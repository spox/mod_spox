class FloodKicker < ModSpox::Plugin
    def initialize(pipeline)
        super
        flood = Models::Group.find_or_create(:name => 'flood')
        @channels = Setting.filter(:name => 'floodkicker').first
        @channels = @channels.nil? ? [] : @channels.value
        @data = {}
        Helpers.load_message(:incoming, :Privmsg)
        @pipeline.hook(self, :listener, ModSpox::Messages::Incoming::Privmsg)
        add_sig(:sig => 'floodkick enable( \S+)?', :method => :add_channel, :group => flood,
                :desc => 'Add channel to flood kicker', :params => [:channel])
        add_sig(:sig => 'floodkick disable( \S+)?', :method => :remove_channel, :group => flood,
                :desc => 'Remove channel from flood kicker', :params => [:channel])
        add_sig(:sig => 'floodkick lines( \d+)?', :method => :max_lines, :group => flood,
                :desc => 'Maximum number of lines in allowed time', :params => [:lines], :req => :public)
        add_sig(:sig => 'floodkick seconds( \d+)?', :method => :max_seconds, :group => flood,
                :desc => 'Maximum number of seconds for allowed lines', :params => [:seconds], :req => :public)
        add_sig(:sig => 'floodkick status( \S+)?', :method => :status, :desc => 'Show parameters for given channel',
                :params => [:channel])
    end
#    @channels -> {:channel => chan.pk, :lines => \d+, :seconds => \d+}
    
    def status(m, params)
        begin
            output = []
            channel = params[:channel] ? Helpers.find_model(params[:channel].strip) : m.is_public? ? m.target : nil
            if(channel.nil? && m.is_public?)
                chan = get_chan(m.target)
                output << "\2#{m.target.name}:\2 #{chan[:lines]} lines in #{chan[:seconds]} seconds"
            elsif(channel)
                chan = get_chan(channel)
                output << "\2#{channel.name}:\2 #{chan[:lines]} lines in #{chan[:seconds]} seconds"
            else
                @channels.each do |c|
                    output << "\2#{Models::Channel[c[:channel]].name}:\2 #{c[:lines]} lines in #{c[:seconds]} seconds"
                end
            end
            information m.replyto, "Status: #{output.join(' ')}"
        rescue Object => boom
            error m.replyto, "Failed to retreive status: #{boom}"
        end
    end
    
    def add_channel(m, params)
        begin
            channel = params[:channel] ? Helpers.find_model(params[:channel].strip) : m.is_public? ? m.target : nil
            raise "Unable to determine channel to enable flood kicker" if channel.nil?
            unless(watched_channels_ids.include?(channel.pk))
                @channels << {:channel => channel.pk, :lines => 5, :seconds => 1}
                save_channels
                information m.replyto, "Flood kicker is now enabled for: #{channel.name}"
            else
                warning m.replyto, "\2Error:\2 Flood kicker is already enabled for: #{channel.name}"
            end
        rescue Object => boom
            error m.replyto, "Failed to enable flood kicker: #{boom}"
        end
    end
    
    def remove_channel(m, params)
        begin
            channel = params[:channel] ? Helpers.find_model(params[:channel].strip) : m.is_public? ? m.target : nil
            raise "Unable to determine channel to disable flood kicker" if channel.nil?
            if(watched_channels_ids.include?(channel.pk))
                @channels.delete(get_chan(channel.pk))
                save_channels
                information m.replyto, "Flood kicker is now disabled for: #{channel.name}"
            else
                warning m.replyto, "Flood kicker is not enabled for: #{channel.name}"
            end
        rescue Object => boom
            error m.replyto, "Failed to disable flood kicker: #{boom}"
        end
    end
    
    def max_lines(m, params)
        lines = params[:lines] ? params[:lines].to_i : nil
        chan = get_chan(m.target.pk)
        unless(chan.nil?)
            if(lines.nil? || lines == 0)
                information m.replyto, "Flood kicker lines for this channel currently set at: #{chan[:lines]} lines"
            else
                chan[:lines] = lines
                save_channels
                information m.replyto, "Flood kicker lines updated to: #{lines} lines"
            end
        else
            error m.replyto, "Flood kicker is not enabled in this channel"
        end
    end
    
    def max_seconds(m, params)
        seconds = params[:seconds] ? params[:seconds].to_i : nil
        chan = get_chan(m.target.pk)
        unless(chan.nil?)
            if(seconds.nil? || seconds == 0)
                information m.replyto, "Flood kicker seconds for this channel currently set at: #{chan[:seconds]} seconds"
            else
                chan[:seconds] = seconds
                save_channels
                information m.replyto, "Flood kicker seconds updated to: #{seconds} seconds"
            end
        else
            error m.replyto, "Flood kicker is not enabled in this channel"
        end
    end
    
    def listener(m)
        return unless m.is_public?
        if(watched_channels_ids.include?(m.target.pk))
            log_message(m)
            if(kick_nick?(m.source, m.target))
                chan = get_chan(m.target.pk)
                clear_nick(m.source, m.target)
                @pipeline << Messages::Outgoing::Kick.new(m.source, m.target, "Flooding. (exceeded #{chan[:lines]} lines in #{chan[:seconds]} seconds)")
            end
        end
    end
    
    private
    
    def log_message(m)
        @data[m.target.pk] = {} unless @data.has_key?(m.target.pk)
        @data[m.target.pk][m.source.pk] = [] unless @data[m.target.pk].has_key?(m.source.pk)
        @data[m.target.pk][m.source.pk] << {:time => Time.now, :message => m.message}
        @data[m.target.pk][m.source.pk].shift until @data[m.target.pk][m.source.pk].size <= get_chan(m.target.pk)[:lines]
    end
    
    def kick_nick?(nick, channel)
        chan = get_chan(channel.pk)
        if(@data[channel.pk].has_key?(nick.pk) && @data[channel.pk][nick.pk].size == chan[:lines])
            return @data[channel.pk][nick.pk][@data[channel.pk][nick.pk].size - 1][:time].to_i - @data[channel.pk][nick.pk][0][:time].to_i <= chan[:seconds].to_i
        else
            return false
        end
    end
    
    def clear_nick(nick, channel)
        @data[channel.pk].delete(nick.pk) if @data[channel.pk].has_key?(nick.pk)
    end
    
    def save_channels
        s = Models::Setting.find_or_create(:name => 'floodkicker')
        s.value = @channels
        s.save
    end
    
    def watched_channels
        @channels.collect{|c| Models::Channel[c[:channel]]}
    end
    
    def watched_channels_ids
        @channels.collect{|c| c[:channel]}
    end
    
    # returns channel information from hash
    def get_chan(pk)
        @channels.each do |c|
            return c if c[:channel] == pk
        end
        nil
    end
end