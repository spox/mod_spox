class Banner < ModSpox::Plugin

    include Models
    include Messages::Outgoing
    
    def initialize(pipeline)
        super(pipeline)
        admin = Group.find_or_create(:name => 'banner')
        Signature.find_or_create(:signature => 'ban (\S+)', :plugin => name, :method => 'default_ban', :group_id => admin.pk,
            :description => 'Kickban given nick from current channel').params = [:nick]
        Signature.find_or_create(:signature => 'ban (\S+) (\S+)', :plugin => name, :method => 'channel_ban', :group_id => admin.pk,
            :description => 'Kickban given nick from given channel').params = [:nick, :channel]
        Signature.find_or_create(:signature => 'ban (\S+) (\S+) (\d+) ?(.+)?', :plugin => name, :method => 'full_ban', :group_id => admin.pk,
            :description => 'Kickban given nick from given channel for given number of seconds').params = [:nick, :channel, :time, :message]
        Signature.find_or_create(:signature => 'banmask (\S+) (\S+) (\d+) ?(.+)?', :plugin => name, :method => 'message_mask_ban', :group_id => admin.pk,
            :description => 'Kickban given mask from given channel for given number of seconds providing an optional message'
            ).params = [:mask, :message, :time, :channel]
        @pipeline.hook(self, :mode_check, :Incoming_Mode)
        BanRecord.create_table unless BanRecord.table_exists?
        BanMask.create_table unless BanMask.table_exists?
        @updater = nil
        updater
    end
    
    def destroy
        updater(false)
    end
    
    def mode_check(message)
        Logger.log("RECIEVED MODE MESSAGE")
    end
    
    def default_ban(message, params)
        params[:time] = 86400
        params[:channel] = message.target.name
        full_ban(message, params)
    end
    
    def channel_ban(message, params)
        params[:time] = 86400
        full_ban(message, params)
    end
    
    def full_ban(message, params)
        nick = Models::Nick.filter(:nick => params[:nick]).first
        channel = Channel.filter(:name => params[:channel]).first
        if(!me.is_op?(message.target))
            reply(message.replyto, "Error: I'm not a channel operator")
        elsif(!nick)
            reply(message.replyto, "#{message.source.nick}: Failed to find nick #{params[:nick]}")
        elsif(!channel)
            reply(message.replyto, "#{message.source.nick}: Failed to find channel #{params[:channel]}")
        else
            ban(nick, channel, params[:time], params[:message])
        end
    end
    
    # nick:: ModSpox::Models::Nick to ban
    # channel:: ModSpox::Models::Channel to ban nick from
    # time:: number of seconds ban should last
    # reason:: reason for the ban
    # invite:: invite nick back to channel when ban expires
    # show_time:: show ban time in kick message
    def ban(nick, channel, time, reason, invite=false, show_time=true)
        raise Exceptions::InvalidType.new("Nick given is not a nick model") unless nick.is_a?(Models::Nick)
        raise Exceptions::InvalidType.new("Channel given is not a channel model") unless nick.is_a?(Models::Channel)
        if(!me.is_op?(channel))
            raise Exceptions::NotOperator.new("I am not an operator in #{channel.name}")
        elsif(!nick.channels.include?(channel))
            raise Exceptions::NotInChannel.new("#{nick.nick} is not in channel: #{channel.name}")
        else
            mask = nick.source.nil? || nick.source.empty? ? "#{nick.nick}!*@*" : "*!*@#{nick.address}"
            BanRecord.new(:nick_id => nick.pk, :bantime => time.to_i, :remaining => time.to_i,
                :invite => invite, :channel_id => channel.pk, :mask => mask).save
            message = reason ? reason : 'no soup for you!'
            message = "#{message} (#{Helpers.format_secs(time.to_i)} ban)" if show_time
            @pipeline << ChannelMode.new(channel, '+b', mask)
            @pipeline << Kick.new(nick, channel, message)
            updater
        end
    end
    
    # mask:: mask to match against source (Regexp)
    # channel:: ModSpox::Models::Channel to ban from
    # message:: kick message
    # time:: time ban on mask should stay in place
    # Bans all users who's source matches the given mask
    def mask_ban(mask, channel, message, time)
        raise NotInChannel.new("I am not in channel: #{channel.name}") unless me.channels.include?(channel)
        BanMask.new(:mask => mask, :channel_id => channel.pk, :message => message, :bantime => time.to_i, :stamp => Object::Time.now).save
        check_masks
        updater
    end
    
    def message_mask_ban(message, params)
        channel = params[:channel] ? Channel.filter(:name => params[:channel]).first : message.target
        if(channel)
            begin
                mask_ban(params[:mask], channel, params[:mesasge], params[:time])
            rescue Object => boom
                reply(message.replyto, "Error: Failed to ban mask. Reason: #{boom}")
                Logger.log("ERROR: #{boom} #{boom.backtrace.join("\n")}")
            end
        else
            reply(message.replyto, "Error: No record of channel: #{params[:channel]}")
        end 
    end
    
    def check_masks
        masks = BanMask.map_masks
        masks.keys.each do |channel_name|
            channel = Channel.filter(:name => channel_name).first
            if(me.is_op?(channel))
                channel.nicks.each do |nick|
                    match = nil
                    masks[channel.name].each do |mask|
                        if(nick.source =~ /#{mask[:mask]}/)
                            match = mask if mask.nil? || mask[:bantime].to_i > match[:bantime].to_i
                        end
                    end
                    ban(nick, channel, match[:bantime], match[:message]) 
                end
            end
        end
    end
    
    def updater(new_record = true)
        unless @updater.nil?
            time = Object::Time.now.to_i - @updater
            BanRecord.filter{:remaining > 0}.update("remaining = remaining - #{time}")
            BanMask.filter{:bantime > 0}.update("bantime = bantime - #{time}")
        end
        BanRecord.filter{:remaining <= 0 && :removed == false}.each do |record|
            if(me.is_op?(record.channel))
                @pipeline << ChannelMode.new(record.channel, '-b', record.mask)
                record.set(:removed => true)
                @pipeline << Invite.new(record.nick, record.channel) if record.invite
            end
        end
        BanMask.filter{:bantime < 1}.destroy
        next_ban_record = BanRecord.filter{:remaining > 0}.order(:remaining.ASC).first
        next_mask_record = BanMask.filter{:bantime > 0}.order(:bantime.ASC).first
        time = next_ban_record ? next_ban_record.remaining : 0
        time = next_mask_record && next_mask_record.bantime > time ? next_mask_record.bantime : time
        if(time > 0 && new_record)
            @updater = Object::Time.now.to_i
            @pipeline << Messages::Internal::TimerAdd.new(self, time, nil, true){ updater }
        end
    end
    
    class BanRecord < Sequel::Model
        set_schema do
            primary_key :id
            timestamp :stamp, :null => false
            integer :bantime, :null => false, :default => 1
            integer :remaining, :null => false, :default => 1
            text :mask, :null => false
            boolean :invite, :null => false, :default => false
            boolean :removed, :null => false, :default => false
            foreign_key :channel_id, :null => false, :table => :channels
            foreign_key :nick_id, :null => false, :table => :nicks
        end
        
        before_create do
            set :stamp => Time.now
        end
        
        def channel
            ModSpox::Models::Channel[channel_id]
        end
        
        def nick
            ModSpox::Models::Nick[nick_id]
        end
    end
    
    class BanMask < Sequel::Model
        set_schema do
            primary_key :id
            text :mask, :unique => true, :null => false
            timestamp :stamp, :null => false
            integer :bantime, :null => false, :default => 1
            text :message
            foreign_key :channel_id, :null => false, :table => :channels
        end
        
        def channel
            ModSpox::Models::Channel[channel_id]
        end
        
        def self.map_masks
            masks = {}
            BanMask.all.each do |mask|
                Logger.log("Processing mask for channel: #{mask.channel.name}")
                masks[mask.channel.name] = [] unless masks.has_key?(mask.channel.name)
                masks[mask.channel.name] << {:mask => mask.mask, :message => mask.message, :bantime => mask.bantime, :channel => mask.channel}
            end
            return masks
        end
    end
    
    class NotOperator < Exceptions::BotException
    end
    
    class NotInChannel < Exceptions::BotException
    end

end