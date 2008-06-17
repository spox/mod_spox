class AutoKick < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        group = Group.find_or_create(:name => 'autokick')
        Signature.find_or_create(:signature => 'autokick list', :plugin => name, :method => 'list', :group_id => group.pk,
            :description => 'List active autokick rules')
        Signature.find_or_create(:signature => 'autokick add (#\S+) (\d+) (\S+) (.+)', :plugin => name, :method => 'add',
            :group_id => group.pk, :description => 'Add new autokick rule for current channel',
            :requirement => 'public').params = [:channel, :time, :regex, :message]
        Signature.find_or_create(:signature => 'autokick add (\d+) (\S+) (.+)', :plugin => name, :method => 'add',
            :group_id => group.pk, :description => 'Add a new autokick rule').params = [:time, :regex, :message]
        Signature.find_or_create(:signature => 'autokick remove (\d+)', :plugin => name, :method => 'remove',
            :group_id => group.pk, :description => 'Remove an autokick rule').params = [:id]
        @pipeline.hook(self, :banner_watch, :Internal_PluginResponse)
        @banner = nil
        @map = nil
        AutoKickRecord.create_table unless AutoKickRecord.table_exists?
        do_listen
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
        if(@map.keys.include?(message.target.pk))
            @map[message.target.pk].each do |pattern|
                reg = Regexp.new(pattern, Regexp::IGNORECASE)
                unless(reg.match(message.message).nil?)
                    record = AutoKickRecord.filter(:pattern => pattern).first
                    @banner.plugin.ban(message.source, message.target, record.bantime, record.message, invite=false, show_time=true)
                end
            end 
        end
    end
    
    def banner_watch(message)
        if(message.origin == self && message.found?)
            @banner = message.plugin
        end
    end
    
    private
    
    def do_listen
        @map = nil
        begin
            @pipeline.unhook(self, :listener, :Incoming_Privmsg)
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
            @pipeline << Messages::Internal::PluginRequest.new(self, 'Banner')
            @pipeline.hook(self, :listener, :Incoming_Privmsg)
        end
    end
    
    class AutoKickRecord < Sequel::Model
        set_schema do
            primary_key :id
            text :pattern, :null => false
            integer :bantime, :null => false, :default => 60
            text :message, :null => false
            foreign_key :channel_id, :table => :channels
        end
        
        def channel
            ModSpox::Models::Channel[channel_id]
        end
    end

end