['etc', 
 'mod_spox/Database',
 'mod_spox/BotConfig',
 'mod_spox/BaseConfig'].each{|f|require f}


module ModSpox

    class ConfigurationWizard
    
        def initialize
            @echo = nil
            @config = Array.new
            @config_db = Hash.new
            @stuck_visible = true
            begin
                require 'termios'
                @stuck_visible = false
            rescue Object => boom
            end
        end
    
        # Run the configuration wizard
        def run
            config = {}
            puts "*********************************"
            puts "* mod_spox Configuration Wizard *"
            puts "*********************************"
            puts ""
            config[:irc_server] = get_input('IRC Server: ', '.+', nil)
            config[:irc_port] = get_input('IRC Port: ', '\d+', '6667')
            config[:reconnect_wait] = get_input('Reconnect wait time: ', '\d+', 10)
            config[:bot_nick] = get_input('IRC Nick: ', '[a-zA-Z].*', 'mod_spox')
            config[:bot_password] = get_input('IRC Nick Password (for nickserv): ', '.*', nil)
            config[:bot_username] = get_input('IRC Username: ', '.+', 'mod_spox')
            config[:bot_realname] = get_input('IRC Real Name: ', '.+', 'mod_spox IRC bot')
            config[:socket_burst] = get_input('Socket burst rate (lines): ', '\d+', '3')
            config[:socket_burst_in] = get_input('Socket burst time: ', '\d+', '2')
            config[:socket_burst_delay] = get_input('Socket burst delay: ', '\d+', '2')
            config[:admin_nick] = get_input('Administator nick: ', '[a-zA-Z].*', nil)
            config[:admin_password] = get_input('Administrator password: ', '.+', nil)
            config[:plugin_directory] = get_input('Plugin temp data driectory (bot needs write permission): ', '.+', '/tmp')
            config[:trigger] = get_input('Default trigger: ', '.+', '!')
            config[:memcache] = get_input('Use memcache (EXPERIMENTAL): ', '(yes|no)', 'no')
            valid_connection = false
            until valid_connection do
                config[:db_adapter] = get_input('Database type (pgsql|sqlite|mysql): ', '(pgsql|sqlite|mysql)', 'sqlite')
                unless(config[:db_adapter] == 'sqlite')
                    config[:db_username] = get_input('Database username: ', '.+', 'mod_spox')
                    config[:db_password] = get_input('Database password: ', '.*', nil)
                    config[:db_host] = get_input('Database host: ', '.*', '127.0.0.1')
                    config[:db_database] = get_input('Database name: ', '.+', 'mod_spox')
                end
                begin
                    print 'Testing database connection... '
                    config[:db_adapter] == 'sqlite' ? test_connection(config[:db_adapter]) : test_connection(config[:db_adapter], config[:db_username], config[:db_password], config[:db_host], config[:db_database])
                    puts 'OK'
                    valid_connection = true
                rescue Sequel::DatabaseError, URI::InvalidURIError => boom
                    puts 'Failed'
                    puts 'Error: Connection to database failed'
                    puts "Info: #{boom}"
                rescue Object => boom
                    puts 'Failed'
                    puts 'Error: Unexpected error encountered.'
                    puts "Info: #{boom}"
                ensure
                    $stdout.flush
                end
            end
            print "Storing configuration values... "
            begin
                save_configuration(config)
                puts 'OK'
                puts 'mod_spox is now configured and ready for use'
            rescue Object => boom
                puts 'Failed'
                puts "Error: #{boom}"
                puts 'Please try running the configuration again'
            end
        end
        
        def update
            run
        end
        
        private
        
        def test_connection(type, username=nil, password=nil, host=nil, name=nil)
            case type
                 when 'mysql'
                     c = Sequel.mysql(name, :user => username, :password => password, :host => host)
                     c.test_connection
                when 'pgsql'
                    c = Sequel.connect("#{ModSpox.jdbc ? 'jdbc:' : ''}postgres://#{username}:#{password}@#{host}/#{name}")
                    c.test_connection
                when 'sqlite'
                    return true
            end
        end
        
        # Save our configuration values
        def save_configuration(uconfig)
            config = BaseConfig.new(BotConfig[:userconfigpath])
            uconfig.each_pair do |key,value|
                config[key] = value if key.to_s =~ /^(db|memcache)/
            end
            config.write_configuration
            ModSpox.initialize_bot
            require  'mod_spox/models/Models'
            require 'mod_spox/Helpers'
            Sequel::Migrator.apply(Database.db, BotConfig[:libpath] + '/migrations')
            uconfig.each_pair do |key,value|
                unless key.to_s =~ /^(db|irc|admin|trigger)/
                    m = Models::Config.find_or_create(:name => key.to_s)
                    m.value = value
                    m.save
                end
            end
            s = Models::Server.find_or_create(:host => uconfig[:irc_server], :port => uconfig[:irc_port])
            n = Models::Nick.find_or_create(:nick => uconfig[:admin_nick])
            a = Models::Auth.find_or_create(:nick_id => n.pk)
            g = Models::Group.find_or_create(:name => 'admin')
            a.add_group(g)
            a.password = uconfig[:admin_password]
            a.save
            t = Models::Trigger.find_or_create(:trigger => uconfig[:trigger])
            t.active = true
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
        def read_input(pattern=nil, default=nil)
            #input_echo(echo)
            response = $stdin.readline
            response.strip!
            set = response.length > 0
            unless(pattern.nil?)
                response = nil unless response =~ /^#{pattern}$/
            end
            if(default && !set)
                response = default
            end
            #input_echo(true) unless echo
            #puts "" unless echo
            return response
        end
        
        # output:: to send before user input
        # regex:: pattern user input must match (^ and $ not needed. applied automatically)
        # echo:: echo user's input
        # default:: default value if no value is entered
        def get_input(output, regex, default=nil)
            response = nil
            until(response) do
                print output
                print "[#{default}]: " unless default.nil?
                $stdout.flush
                response = read_input(regex, default)
            end
            return response
        end
    
    end

end
