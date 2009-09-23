class Filters < ModSpox::Plugin
    def initialize(pipeline)
        super
        group = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'filter (in|out) list', :method => :list, :group => group, :desc => 'List enabled filters', :params => [:direction])
        add_sig(:sig => 'filter (in|out) add (\S+) (.+)', :method => :add, :group => group, :params => [:direction, :name, :code], :desc => 'Add new filter')
        add_sig(:sig => 'filter (in|out) remove (\S+)', :method => :remove, :group => group, :params => [:direction, :name], :desc => 'Remove filter')
        add_sig(:sig => 'filter (in|out) show (\S+)', :method => :show, :group => group, :params => [:direction, :name], :desc => 'Show the contents of the filter')
        add_sig(:sig => 'ignore (\S+)( \S+)?', :method => :ignore, :group => group, :params => [:nick, :channel], :desc => 'Ignore a given nick. If no channel is provided, all input is ignored from user')
        add_sig(:sig => 'unignore (\S+)( \S+)?', :method => :unignore, :group => group, :params => [:nick, :channel], :desc => 'Remove a nick from an ignore list')
        add_sig(:sig => 'ignores', :method => :ignores, :desc => 'List of ignored nicks')
        add_sig(:sig => 'quiet( \S+)?', :method => :quiet, :group => group, :params => [:channel], :desc => 'Be quiet in channel')
        add_sig(:sig => 'unquiet( \S+)?', :method => :unquiet, :group => group, :params => [:channel], :desc => 'Don\'t be quiet in channel')
        add_sig(:sig => 'quiets', :method => :quiets, :desc => 'List of quiet channels')
        @filters = {}
        @filters[:in] = RubyFilter.new(Messages::Incoming::Privmsg)
        @filters[:out] = RubyFilter.new(Messages::Outgoing::Privmsg)
        @filters[:ignore] = IgnoreFilter.new(Messages::Incoming::Privmsg)
        @filters[:quiet] = QuietFilter.new(Messages::Outgoing::Privmsg)
        load_strings
        @filters[:in].filters = @filter_strings[:in].values if @filter_strings[:in].size > 0
        @filters[:out].filters = @filter_strings[:out].values if @filter_strings[:out].size > 0
        @filters[:ignore].ignores = @filter_strings[:ignore]
        @filters[:quiet].quiets = @filter_strings[:quiet]
        [
            [@filters[:in], ModSpox::Messages::Incoming::Privmsg], [@filters[:out], ModSpox::Messages::Outgoing::Privmsg],
            [@filters[:ignore], ModSpox::Messages::Incoming::Privmsg], [@filters[:quiet], ModSpox::Messages::Outgoing::Privmsg]
        ].each do |f|
            @pipeline << ModSpox::Messages::Internal::FilterAdd.new(f[0], f[1])
        end
    end
    
    def ignore(m, params)
        begin
            if(params[:channel])
                chan = Helpers.find_model(params[:channel].strip)
                raise "#{params[:channel].strip} is not a valid channel" unless chan.is_a?(Models::Channel)
                @filters[:ignore].ignore(m.source, chan)
            else
                @filters[:ignore].ignore(m.source)
            end
            information m.replyto, "#{m.source.nick} is now ignored #{params[:channel] ? "in #{params[:channel].strip}" : 'everywhere'}"
        rescue Object => boom
            error m.replyto, "Failed to add ignore: #{boom}"
        end
    end
    
    def unignore(m, params)
        begin
            if(params[:channel])
                chan = Helpers.find_model(params[:channel].strip)
                raise "#{params[:channel].strip} is not a valid channel" unless chan.is_a?(Models::Channel)
                @filters[:ignore].unignore(m.source, chan)
            else
                @filters[:ignore].unignore(m.source)
            end
            information m.replyto, "#{m.source.nick} is no longer ignored #{params[:channel] ? "in #{params[:channel].strip}" : 'everywhere'}"
        rescue Object => boom
            error m.replyto, "Failed to remove ignore: #{boom}"
        end
    end
    
    def quiet(m, params)
        begin
            if(params[:channel])
                chan = Helpers.find_model(params[:channel].strip)
                raise "#{params[:channel.strip} is not a valid channel" unless chan.is_a?(Models::Channel)
                @filters[:quiet].quiet(chan)
                information m.replyto, "Now quiet in channel: #{chan.name}"
            elsif(m.is_public?)
                @filters[:quiet].quiet(m.target)
                information m.source, "Now quiet in channel: #{m.target.name}"
            else
                raise "failed to determine where to be quiet"
            end
        rescue Object => boom
            error m.replyto, "Failed to add quiet: #{boom}"
        end
    end
    
    def unquiet(m, params)
        begin
            if(params[:channel])
                chan = Helpers.find_model(params[:channel].strip)
                raise "#{params[:channel.strip} is not a valid channel" unless chan.is_a?(Models::Channel)
                @filters[:quiet].unquiet(chan)
                information m.replyto, "Now not quiet in channel: #{chan.name}"
            elsif(m.is_public?)
                @filters[:quiet].unquiet(m.target)
                information m.source, 'okay'
            else
                raise "failed to determine where to not be quiet"
            end
        rescue Object => boom
            error m.replyto, "Failed to remove quiet: #{boom}"
        end
    end
    
    def add(m, params)
        begin
            name = params[:name].to_sym
            direction = params[:direction].to_sym
            raise "Key is already in use. Please choose another name (#{name})" if @filter_strings[direction][name]
            @filter_strings[direction][name] = params[:code]
            @filters[direction].filters = @filter_strings[direction].values
            save_strings
            information m.replyto, "New filter has been applied under name: #{name}"
        rescue Object => boom
            error m.replyto, "Failed to apply new filter string under name: #{name}. Reason: #{boom}"
        end
    end

    def remove(m, params)
        begin
            name = params[:name].to_sym
            direction = params[:direction].to_sym
            raise "Failed to locate filter key: #{name}" unless @filters[direction][name]
            @filters_strings[direction].delete(name)
            @filters[direction].filters = @filter_strings[direction]
            save_strings
            information m.replyto, "Filter #{name} has been removed"
        rescue Object => boom
            error m.replyto, "Failed to remove filter named: #{name}. Reason: #{boom}"
        end
    end

    def list(m, params)
        begin
            direction = params[:direction].to_sym
            if(@filters_strings[direction].empty?)
                warning m.replyto, 'There are currently no filters applied'
            else
                information m.replyto, "Filters for #{direction}: #{@filter_strings[direction].keys.sort}"
            end
        rescue Object => boom
            error m.replyto, "Failed to generate list. Reason: #{boom}"
        end
    end

    def show(m, params)
        begin
            direction = params[:direction].to_sym
            name = params[:name].to_sym
            if(@filter_strings[direction][name])
                information m.replyto, "#{name}: #{@filter_strings[direction][name]}"
            else
                error m.replyto, "Failed to locate filter named: #{name}"
            end
        rescue Object => boom
            error m.replyto, "Failed to locate filter. Reason: #{boom}"
        end
    end

    private

    def load_strings
        @filter_strings = Models::Setting.find_or_create(:name => 'filters').value
        @filter_strings = {:in => {}, :out => {}, :quiet => nil, :ignore => nil} unless @filter_strings.is_a?(Hash)
    end

    def save_strings
        v = Models::Setting.find_or_create(:name => 'filters')
        v.value = {:in => @filters[:in].filters, :out => @filters[:out].filters, :quiet => @filters[:quiet].quiets, :ignore => @filters[:ignore].ignores}
        v.save
    end
    class RubyFilter < ModSpox::Filter
        def initialize(args)
            super
            @filters = []
        end
        def filters
            @filters.dup
        end
        def filters=(f)
            raise ArgumentError.new('Array of filter strings required') unless f.is_a?(Array)
            @filters = f.dup
        end
        def do_filter(m)
            @filters.each do |f|
                begin
                    Kernel.eval(f)
                rescue Object => boom
                    Logger.error("Failed to apply filter string: #{boom}")
                end
            end
            return m
        end
    end
    class IgnoreFilter < ModSpox::Filter
        def initialize(args)
            super
            @ignores = {:all => []}
        end
        def ignores
            @ignores.dup
        end
        def ignores=(i)
            @ignores = i.dup
        end
        def ignore(nick, channel=nil)
            key = channel.nil? ? :all : channel.pk
            @ignores[key] = [] unless @ignores[key]
            unless(@ignores.include?(nick.pk))
                @ignores[key] << nick.pk
            else
                raise "Nick #{nick.nick} is already set to ignore #{channel.nil? ? 'everywhere' : "in #{channel.name}"}"
            end
        end
        def unignore(nick, channel=nil)
            key = channel.nil? ? :all : channel.pk
            if(@ignores[key] && @ignores[key].include?(nick.pk))
                @ignores[key].delete(nick.pk)
                @ignores.delete(key) if @ignores[key].empty?
            else
                raise "Nick #{nick.nick} is not currently set to ignore #{channel.nil? ? 'everywhere' : "in #{channel.name}"}"
            end
        end
    end
    class QuietFilter < ModSpox::Filter
        def initialize(args)
            @quiet = []
        end
        def quiets
            @quiet.dup
        end
        def quiets=(q)
            @quiet = q.dup
        end
        def quiet(channel)
            unless(@quiet.include?(channel.pk))
                @quiet << channel.pk
            else
                raise "Already set to quiet in #{channel.name}"
            end
        end
        def unquiet(channel)
            if(@quiet.include?(channel.pk))
                @quiet.delete(channel.pk)
            else
                raise "Not currently set to quiet in #{channel.name}"
            end
        end
        def do_filter(m)
            return @quiet.include?(m.channel.pk) ? nil : m
        end
    end
end
