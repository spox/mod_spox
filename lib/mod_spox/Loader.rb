['mod_spox/Exceptions',
 'mod_spox/BotConfig',
 'mod_spox/BaseConfig',
 'mod_spox/Database',
 'logger'].each{|f|require f}

module ModSpox
    
    # Loads all files needed by the bot
    def self.initialize_bot(db=nil)
        setup_adapter(db)
        check_upgrade
    end
    
    # Setup the DataMapper adapter
    def self.setup_adapter(db=nil)
        memcache = false
        config = BaseConfig.new(BotConfig[:userconfigpath])
        if(config[:memcache] == 'on')
            begin
                require 'memcache'
                memcache = true
                Database.cache = MemCache.new('localhost:11211', :namespace => 'modspox')
            rescue Object => boom
                puts "FAILED TO LOAD MEMCACHE SUPPORT: #{boom}"
                # do nothing #
            end
        end
        unless(db.nil?)
            Database.db = db
        else
            case config[:db_adapter]
                when 'mysql'
                    Database.db = Sequel.mysql(config[:db_database], :user => config[:db_username],
                            :password => config[:db_password], :host => config[:db_host], :max_connections => 20)
                    Database.type = :mysql
                when 'pgsql'
                    Database.db = Sequel.connect("#{ModSpox.jdbc ? 'jdbc:' : ''}postgres://#{config[:db_username]}:#{config[:db_password]}@#{config[:db_host]}/#{config[:db_database]}")
                    Database.type = :pgsql
                when 'sqlite'
                    Database.db = Sequel.sqlite("#{BotConfig[:userpath]}/mod_spox.db", :pool_timeout => 20, :timeout => 5000)
                    Database.type = :sqlite
            end
        end
    end
    
    # check if the bot has been upgraded
    def self.check_upgrade
        Sequel::Migrator.apply(Database.db, BotConfig[:libpath] + '/migrations')
        config = BaseConfig.new(BotConfig[:userconfigpath])
        config[:plugin_upgrade] = 'no'
        begin
            config[:plugin_upgrade] = 'yes' if config[:last_version] != ModSpox.botversion
        rescue Exceptions::UnknownKey => boom
            config[:plugin_upgrade] = 'yes'
        end
        config[:last_version] = ModSpox.botversion
    end
    
end