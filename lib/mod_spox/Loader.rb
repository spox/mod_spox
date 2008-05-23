['mod_spox/Exceptions',
 'mod_spox/BotConfig',
 'mod_spox/BaseConfig',
 'mod_spox/Database'].each{|f|require f}

module ModSpox
    
    # Loads all files needed by the bot
    def initialize_bot
        setup_adapter
    end
    
    # Setup the DataMapper adapter
    def setup_adapter
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
        case config[:db_adapter]
            when 'mysql'
                Database.db = Sequel.mysql(config[:db_database], :user => config[:db_username],
                        :password => config[:db_password], :host => config[:db_host])
                Database.type = :mysql
            when 'pgsql'
                Database.db = Sequel.open("postgres://#{config[:db_username]}:#{config[:db_password]}@#{config[:db_host]}/#{config[:db_database]}")
                Database.type = :pgsql
            when 'sqlite'
                Database.db = Sequel.sqlite "#{BotConfig[:userpath]}/mod_spox.db"
                Database.type = :sqlite
        end
    end

end