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
        @pipeline.hook(self, :join_check, :Incoming_Join)
        @pipeline.hook(self, :who_check, :Incoming_Who)
        @pipeline.hook(self, :get_action, :Internal_TimerResponse)
        BanRecord.create_table unless BanRecord.table_exists?
        BanMask.create_table unless BanMask.table_exists?
        @action = nil
        @pipeline << Messages::Internal::TimerAdd.new(self, 0.5){ updater }
    end
    
    def destroy
        updater
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
        raise Exceptions::InvalidType.new("Channel given is not a channel model") unless channel.is_a?(Models::Channel)
        if(!me.is_op?(channel))
            raise Exceptions::NotOperator.new("I am not an operator in #{channel.name}")
        elsif(!nick.channels.include?(channel))
            raise Exceptions::NotInChannel.new("#{nick.nick} is not in channel: #{channel.name}")
        else
            mask = nick.source.nil? || nick.source.empty? ? "#{nick.nick}!*@*" : "*!*@#{nick.address}"
            BanRecord.new(:nick_id => nick.pk, :bantime => time.to_i, :remaining => time.to_i,
                :invite => invite, :channel_id => channel.pk, :mask => mask).save
            message = reason ? reason : 'no soup for you!'
            message = "#{message} (Duration: #{Helpers.format_seconds(time.to_i)})" if show_time
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
                mask_ban(params[:mask], channel, params[:message], params[:time])
                reply(message.replyto, "Okay")
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
                        Logger.log("MASK IS NIL") if mask.nil?
                        if(nick.source =~ /#{mask[:mask]}/)
                            match = mask if match.nil? || mask[:bantime].to_i > match[:bantime].to_i
                        end
                    end
                    unless match.nil?
                        begin
                            ban(nick, channel, match[:bantime], match[:message]) 
                        rescue Object => boom
                            Logger.log("Mask based ban failed. Reason: #{boom}")
                        end
                    end
                end
            else
                Logger.log("Ban masks will not be processed due to lack of operator status")
            end
        end
    end
    
    def mask_check(nick, channel)
        return unless me.is_op?(channel)
        updater
        match = nil
        BanMask.filter(:channel_id => channel.pk).each do |bm|
            if(nick.source =~ /#{bm.mask}/)
                match = bm if match.nil? ||  match.bantime < bm.bantime
            end
        end
        unless(match.nil?)
            begin
                ban(nick, channel, match.bantime, match.message)
            rescue Object => boom
                Logger.log("Mask based ban failed. Reason: #{boom}")
            end
        end
    end
    
    # message:: ModSpox::Messages::Incoming::Mode
    # Check for mode changes. Remove pending ban removals if
    # done manually
    def mode_check(message)
        if(message.target.is_a?(String))
            if(message.mode == '-b')
                BanRecord.filter(:mask => message.target, :channel_id => message.channel.pk).each do |match|
                    match.set(:remaining => 0)
                    match.set(:removed => true)
                end
                updater
            end
        end
    end
    
    # message:: ModSpox::Messages::Incoming::Join
    # Check is nick is banned
    def join_check(message)
        mask_check(message.nick, message.channel)
    end
    
    # message:: ModSpox::Messages::Incoming::Who
    # Check if we updated any addresses
    def who_check(message)
        check_masks
    end
    
    def get_action(message)
        @action = message.action
        @sleep = Object::Time.now
        updater
    end
    
    def updater
        return unless @action
        time = (Object::Time.now - @sleep).to_i
        @sleep = Object::Time.now
        Logger.log("TIME LOGGED ASLEEP: #{time}")
        if(time > 0)
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
        time > 0 ? @action.reset_period(time) : @action.suspend        
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