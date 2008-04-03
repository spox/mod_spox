class Banner < ModSpox::Plugin

    include Models
    include Messages::Outgoing
    
    def initialize(pipeline)
        super(pipeline)
        admin = Group.filter(:name => 'admin').first
        Signature.new(:signature => 'ban (\S+)', :plugin => name, :method => :default_ban, :group_id => admin.pk,
            :description => 'Kickban given nick from current channel').params = [:nick]
        Signature.new(:signature => 'ban (\S+) (\S+)', :plugin => name, :method => :channel_ban, :group_id => admin.pk,
            :description => 'Kickban given nick from given channel').params = [:nick, :channel]
        Signature.new(:signature => 'ban (\S+) (\S+) (\d+) ?(.+)?', :plugin => name, :method => :full_ban, :group_id => admin.pk,
            :description => 'Kickban given nick from given channel for given number of seconds').params = [:nick, :channel, :time, :message]
        Signature.new(:signature => 'banmask (\S+) (\S+) (\d+) ?(.+)?', :plugin => name, :method => :mask_ban, :group_id => admin.pk,
            :description => 'Kickban given mask from given channel for given number of seconds providing an optional message',
            ).params = [:mask, :channel, :time, :message]
    end
    
    def default_ban(message, params)
    end
    
    def channel_ban(message, params)
    end
    
    def full_ban(message, params)
    end
    
    def mask_ban(message, params)
    end
    
    class BanRecord < Sequel::Model
        set_scehema do
            primary_key :id
            timestamp :stamp, :null => false
            integer :bantime, :null => false, :default => 1
            integer :remaining, :null => false, :default => 1
            text :mask, :null => false
            boolean :invite, :null => false, :default => false
            foreign_key :channel_id, :null => false, :table => :channels
            foreign_key :nick_id, :null => false, :table => :nicks
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