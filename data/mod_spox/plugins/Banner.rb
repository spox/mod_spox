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
        Signature.find_or_create(:signature => 'banmask (\S+) (\S+) (\d+) ?(.+)?', :plugin => name, :method => 'mask_ban', :group_id => admin.pk,
            :description => 'Kickban given mask from given channel for given number of seconds providing an optional message'
            ).params = [:mask, :channel, :time, :message]
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
        elsif(nick)
            mask = nick.source.nil? ? "#{nick.nick}!*@*" : "*!*@#{nick.address}" 
            BanRecord.new(:nick_id => nick.pk, :bantime => params[:time].to_i, :remaining => params[:time].to_i,
                :invite => false, :channel_id => channel.pk, :mask => mask).save
            message = params[:message] ? params[:message] : 'no soup for you!'
            @pipeline << ChannelMode.new(channel, '+b', mask)
            @pipeline << Kick.new(nick, channel, message)
            updater
        end
    end
    
    def mask_ban(message, params)
    end
    
    def updater(new_record = true)
        unless @updater.nil?
            time = Object::Time.now.to_i - @updater
            BanRecord.filter{:remaining > 0}.update("remaining = remaining - #{time}")
        end
        BanRecord.filter{:remaining < 0 && :removed == false}.each do |record|
            if(me.is_op?(record.channel))
                @pipeline << ChannelMode.new(record.channel, '-b', record.mask)
                record.set(:removed => true)
                @pipeline << Invite.new(record.nick, record.channel) if record.invite
            end
        end
        next_record = BanRecord.filter{:remaining > 0}.order(:remaining.ASC).first
        if(next_record && new_record)
            @updater = Object::Time.now.to_i
            @pipeline << Messages::Internal::TimerAdd.new(self, next_record.remaining, true){ updater }
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
    end
    
    class BanMask < Sequel::Model
        set_schema do
            primary_key :id
            timestamp :stamp, :null => false
            integer :bantime, :null => false, :default => 1
            text :message
            foreign_key :channel_id, :null => false, :table => :channels
        end
    end

end