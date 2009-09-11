class AutoKick < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        Helpers.load_message(:incoming, :Privmsg)
        group = Group.find_or_create(:name => 'autokick')
        add_sig(:sig => 'autokick list', :method => :list, :group => group, :desc => 'List active autokick rules')
        add_sig(:sig => 'autokick add (#\S+) (\d+) (\S+) (.+)', :method => :add, :group => group, :desc => 'Add new autokick rule for current channel', :req => 'public', :params => [:channel, :time, :regex, :message])
        add_sig(:sig => 'autokick add (\d+) (\S+) (.+)', :method => :add, :group => group, :desc => 'Add a new autokick rule', :params => [:time, :regex, :message])
        add_sig(:sig => 'autokick remove (\d+)', :method => :remove, :group => group, :desc => 'Remove an autokick rule', :params => [:id])
        add_sig(:sig => 'autokick colors ?(on|off)?', :method => :colors, :group => group, :desc => 'Kick user for using colors', :req => 'public', :params => [:action])
        @map = nil
        @colors = Setting.val(:colorkick)
        @colors = Array.new unless @colors.is_a?(Array)
        AutoKickRecord.create_table unless AutoKickRecord.table_exists?
        do_listen
    end

    def colors(message, params)
        if(params[:action])
            if(params[:action] == 'on')
                if(@colors.include?(message.target.pk))
                    reply message.replyto, 'Colored autokick is already enabled'
                else
                    @colors << message.target.pk
                    record = Setting.find_or_create(:name => 'colorkick')
                    record.value = @colors
                    record.save
                    reply message.replyto, 'Colored autokick has been enabled'
                end
            else
                @colors.delete(message.target.pk)
                record = Setting.find_or_create(:name => 'colorkick')
                record.value = @colors
                record.save
                reply message.replyto, 'Colored autokick has been disabled'
            end
        else
            status = @colors.include?(message.target.pk) ? 'on' : 'off'
            reply message.replyto, "Colored autokick is currently \2#{status}\2"
        end
    end

    def list(message, params)
        records = AutoKickRecord.all
        unless(records.empty?)
            records.each do |record|
                reply message.replyto, "\2ID:\2 #{record.pk} \2Channel:\2 #{record.channel.name} \2Pattern:\2 #{record.pattern} \2Ban Time:\2 #{Helpers.format_seconds(record.bantime)} \2Kick Message:\2 #{record.message}"
            end
        else
            reply message.replyto, 'No rules currently enabled'
        end
    end

    def add(message, params)
        if(params[:channel])
            channel = Channel.filter(:name => params[:channel]).first
        else
            channel = message.target
        end
        if(channel)
            record = AutoKickRecord.find_or_create(:pattern => params[:regex], :message => params[:message], :bantime => params[:time].to_i, :channel_id => channel.pk)
            reply message.replyto, "New autokick rule has been created"
            do_listen
        else
            reply message.replyto, "\2Error:\2 I have no record of #{params[:channel]}. Failed to add autokick rule."
        end
    end

    def remove(message, params)
        record = AutoKickRecord[params[:id].to_i]
        if(record)
            record.destroy
            reply message.replyto, "Autokick rule \2#{params[:id]}\2 has been removed"
            do_listen
        else
            reply message.replyto, "\2Error:\2 Failed to find an autokick rule with ID: #{params[:id]}"
        end
    end

    def listener(message)
        return unless message.is_public?
        if(@map.keys.include?(message.target.pk))
            bmessage = nil
            btime = 0
            @map[message.target.pk].each do |pattern|
                reg = Regexp.new(pattern, Regexp::IGNORECASE)
                unless(reg.match(message.message).nil?)
                    record = AutoKickRecord.filter(:pattern => pattern).first
                    bmessage = record.message
                    btime += record.bantime
                end
            end
            unless(bmessage.nil?)
                @pipeline << plugin_const(:Banner_Ban).new(message.source, message.target, :kickban, bmessage, btime, false, true)
            end
        end
        if(@colors.include?(message.target.pk))
            if(message.is_colored?)
                @pipeline << plugin_const(:Banner_Ban).new(message.source, message.target, :kickban, 'No color codes allowed', 60, false, true)
            end
        end
    end

    private

    def do_listen
        @map = nil
        begin
            @pipeline.unhook(self, :listener, ModSpox::Messages::Incoming::Privmsg)
        rescue Object => boom
            #ignore
        end
        records = AutoKickRecord.all
        if(records.size > 0)
            @map = {}
            records.each do |record|
                @map[record.channel_id] = [] unless @map[record.channel_id]
                @map[record.channel_id] << record.pattern
            end
            @pipeline.hook(self, :listener, ModSpox::Messages::Incoming::Privmsg)
        end
    end

    class AutoKickRecord < Sequel::Model
        many_to_one :channel, :class => ModSpox::Models::Channel
    end
    
    class AutoKickPersonal < Sequel::Model
        many_to_one :nick, :class => ModSpox::Models::Nick
        many_to_one :channel, :class => ModSpox::Models::Channel
    end

end