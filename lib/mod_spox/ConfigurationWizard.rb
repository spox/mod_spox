['etc', 
 'mod_spox/Database',
 'mod_spox/BotConfig',
 'mod_spox/BaseConfig'].each{|f|require f}


module ModSpox

    class ConfigurationWizard
    
        def initialize
            @echo = nil
            @config = Array.new
            @config << {:id => :db_username, :string => 'Database username: ', :regex => '[a-zA-Z].*', :default => 'mod_spox', :value => nil, :echo => true}
            @config << {:id => :db_password, :string => 'Database password: ', :regex => '.*', :default => nil, :value => nil, :echo => false}
            @config << {:id => :db_host, :string => 'Database host: ', :regex => '.+', :default => 'localhost', :value => nil, :echo => true}
            @config << {:id => :db_database, :string => 'Database name: ', :regex => '.+', :default => 'mod_spox', :value => nil, :echo => true}
            @config << {:id => :db_adapter, :string => 'Database type (mysql|pgsql|sqlite): ', :regex => '(mysql|pgsql|sqlite)', :default => nil, :value => nil, :echo => true}
            @config << {:id => :irc_server, :string => 'IRC Server: ', :regex => '.+', :default => nil, :value => nil, :echo => true}
            @config << {:id => :irc_port, :string => 'IRC Port: ', :regex => '[0-9]+', :default => nil, :value => nil, :echo => true}
            @config << {:id => :reconnect_wait, :string => 'Reconnect wait time: ', :regex => '[0-9]+', :default => '10', :value => nil, :echo => true}
            @config << {:id => :bot_nick, :string => 'IRC Nick: ', :regex => '[a-zA-Z].*', :default => 'mod_spox', :value => nil, :echo => true}
            @config << {:id => :bot_password, :string => 'IRC Nick Password: ', :regex => '.*', :default => nil, :value => nil, :echo => false}
            @config << {:id => :bot_username, :string => 'IRC Username: ', :regex => '.+', :default => 'mod_spox', :value => nil, :echo => true}
            @config << {:id => :bot_realname, :string => 'IRC Real Name: ', :regex => '.+', :default => 'mod_spox IRC bot', :value => nil, :echo => true}
            @config << {:id => :socket_burst, :string => 'Socket burst rate (lines): ', :regex => '[0-9]+', :default => '3', :value => nil, :echo => true}
            @config << {:id => :socket_burst_in, :string => 'Socket burst time: ', :regex => '[0-9]+', :default => '2', :value => nil, :echo => true}
            @config << {:id => :socket_burst_delay, :string => 'Socket burst delay: ', :regex => '[0-9]+', :default => '2', :value => nil, :echo => true}
            @config << {:id => :admin_nick, :string => 'Administrator nick: ', :regex => '[a-zA-Z].*', :default => nil, :value => nil, :echo => true}
            @config << {:id => :admin_password, :string => 'Administrator password: ', :regex => '.+', :default => nil, :value => nil, :echo => false}
            @config << {:id => :plugin_directory, :string => 'Plugin directory (bot must have write priviliges): ', :regex => '.+', :default => nil, :echo => true}
            @config << {:id => :trigger, :string => 'Trigger character for plugins: ', :regex => '.', :default => '!', :value => nil, :echo => true}
            @config << {:id => :memcache, :string => 'Use memcache (EXPERIMENTAL): ', :regex => '(yes|no)', :default => 'no', :value => nil, :echo => true}            
            @stuck_visible = true
            begin
                require 'termios'
                @stuck_visible = false
            rescue Object => boom
            end
        end
    
        # Run the configuration wizard
        def run
            puts "*********************************"
            puts "* mod_spox Configuration Wizard *"
            puts "*********************************"
            puts ""
            @config.each{|v|
                v[:value] = get_input(v[:string], v[:regex], v[:echo], v[:default])
            }
            print "Storing configuration values... "
            save_configuration
            puts "OK"
            puts "mod_spox is now configured and ready for use"
        end
        
        private
        
        def find(key)
            @config.each{|c|
                if(c[:id] == key)
                    return c[:value]
                end
            }
            return nil
        end
        
        # Save our configuration values
        def save_configuration
            config = BaseConfig.new(BotConfig[:userconfigpath])
            @config.each{|value|
                config[value[:id]] = value[:value] if value[:id].to_s =~ /^(db|memcache)/
            }
            config.write_configuration
            initialize_bot
            require  'mod_spox/models/Models'
            require 'mod_spox/Helpers'
            Sequel::Migrator.apply(Database.db, BotConfig[:libpath] + '/migrations')
            @config.each{|value|
                Models::Config[value[:id]] = value[:value] unless value[:id].to_s =~ /^(db|irc|admin|trigger)/
            }
            s = Models::Server.find_or_create(:host => find(:irc_server), :port => find(:irc_port))
            n = Models::Nick.find_or_create(:nick => find(:admin_nick))
            a = Models::Auth.find_or_create(:nick_id => n.pk)
            a.group = Models::Group.find_or_create(:name => 'admin')
            a.password = find(:admin_password)
            a.save
            t = Models::Trigger.find_or_create(:trigger => find(:trigger))
            t.update_with_params(:active => true)
            t.save
        end
        
        # echo:: echo user input
        # Turns echoing of user input on or off
        def input_echo(echo=true)
            return if echo == @echo || @stuck_visible
            term = Termios::getattr($stdin)
            term.c_lflag |= Termios::ECHO if echo
            term.c_lflag &= ~Termios::ECHO unless echo
            Termios::setattr($stdin, Termios::TCSANOW, term)
            @echo = echo
        end
        
        # pattern:: regex response must match
        # default:: default value if response is empty
        # echo:: echo user's input
        # Reads users input
        def read_input(pattern=nil, default=nil, echo=true)
            input_echo(echo)
            response = $stdin.readline
            response.strip!
            set = response.length > 0
            unless(pattern.nil?)
                response = nil unless response =~ /^#{pattern}$/
            end
            if(default && response.nil? && !set)
                response = default
            end
            input_echo(true) unless echo
            puts "" unless echo
            return response
        end
        
        # output:: varchar(255) to send before user input
        # regex:: pattern user input must match (^ and $ not need. applied automatically)
        # echo:: echo user's input
        # default:: default value if no value is entered
        def get_input(output, regex, echo=true, default=nil)
            response = nil
            until(response) do
                print output
                print "[#{default}]: " unless default.nil?
                response = read_input(regex, default, echo)
            end
            return response
        end
    
    end

end