module ModSpox

    # directory:: path to directory
    # Requires all .rb files found within the given directory
    # and all its subdirectories
    def load_directory(directory='')
        base = File.dirname(__FILE__)
        Dir.new("#{base}/#{directory}").each{|item|
            next if ['.', '..'].include?(item)
            if(File.directory?("#{base}/#{directory}/#{item}"))
                load_directory("#{directory}/#{item}")
            elsif(item =~ /\.rb$/)
                item = "#{directory}/#{item}" if directory.length > 0
                begin
                    require "mod_spox/#{item}"
                rescue Object => boom
                    @@failed << item
                end
            end
        }
        @@failed.each{|f| 
            begin
                require "mod_spox/#{f}"
                @@failed.delete(f)
            rescue Object => boom
                # do nothing #
            end
        }
    end
    
    # Loads all files needed by the bot
    def initialize_bot
        setup_adapter
        @@failed = Array.new
        load_directory
        tries = 0
        message = nil
        until @@failed.empty? || tries > 5 do
            @@failed.each{|f|
                begin
                    require "mod_spox/#{f}"
                    @@failed.delete(f)
                rescue Object => boom
                    message = boom
                end
            }
            tries += 1
        end
        if(tries > 5)
            puts 'Failed'
            puts "ERROR: Failed to load required libraries"
            puts "Reason: #{message}"
            puts "#{message.backtrace.join("\n")}"
            exit
        end
    end
    
    # Setup the DataMapper adapter
    def setup_adapter
        require 'mod_spox/Exceptions'
        require 'mod_spox/BotConfig'
        require 'mod_spox/BaseConfig'
        require 'mod_spox/Database'
        memcache = false
        begin
            require 'memcache'
            memcache = true
            Database.cache = MemCache.new('localhost:11211', :namespace => 'modspox')
        rescue Object => boom
            # do nothing #
        end
            
        config = BaseConfig.new(BotConfig[:userconfigpath])
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