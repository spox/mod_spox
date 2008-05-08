['etc', 'mod_spox/Loader',
 'mod_spox/BotConfig',  'mod_spox/BaseConfig'].each{|f|require f}


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
            create_databases
            #Migrators.constants.each{|m| Migrators.const_get(m).apply(Database.db, :up)}
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
        
        def create_databases
            case Database.type
                when :mysql
                    Database.db << "CREATE TABLE IF NOT EXISTS nicks (id int not null auto_increment primary key, nick varchar(255) unique not null, username varchar(255), real_name varchar(255), address varchar(255), source varchar(255), connected_at timestamp, connected_to varchar(255), seconds_idle int, visible boolean not null default false, away boolean not null default false, botnick boolean not null default false)"
                    Database.db << "CREATE TABLE IF NOT EXISTS channels (id int not null auto_increment primary key, name varchar(255) not null, password varchar(255), autojoin boolean not null default false, topic varchar(255), quiet boolean not null default false, parked boolean not null default false)"
                    Database.db << "CREATE TABLE IF NOT EXISTS auths (id int not null auto_increment primary key, password varchar(255), services boolean not null default false, mask varchar(255) unique, authed boolean not null default false, nick_id int unique references nicks)"
                    Database.db << "CREATE TABLE IF NOT EXISTS channel_modes (id int not null auto_increment primary key, mode varchar(255) not null, channel_id int unique not null references channels)"
                    Database.db << "CREATE TABLE IF NOT EXISTS configs (id int not null auto_increment primary key, name varchar(255) unique not null, value varchar(255))"
                    Database.db << "CREATE TABLE IF NOT EXISTS nick_channels (channel_id int not null unique references channels, nick_id int not null unique not null references nicks, primary key(channel_id, nick_id))"
                    Database.db << "CREATE TABLE IF NOT EXISTS nick_modes (id integer primary key auto_increment not null, mode varchar(255) not null, nick_id int not null references nicks, channel_id int references channels, unique index nick_modes_nick_id_channel_id_index (nick_id, channel_id))"
                    Database.db << "CREATE TABLE IF NOT EXISTS servers (id int not null auto_increment primary key, host varchar(255) not null, port int not null default 6667, priority int not null default 0, connected boolean not null default false, unique index servers_server_port_index (server, port))"
                    Database.db << "CREATE TABLE IF NOT EXISTS settings (id int not null auto_increment primary key, name varchar(255) not null unique, value text)"
                    Database.db << "CREATE TABLE IF NOT EXISTS signatures (id int not null auto_increment primary key, signature varchar(255) not null, params varchar(255), group_id int default null references groups, method varchar(255) not null, plugin varchar(255) not null, description varchar(255), requirement enum('public', 'private', 'both') default 'both' not null)"
                    Database.db << "CREATE TABLE IF NOT EXISTS triggers (id int not null auto_increment primary key, `trigger` varchar(255) unique not null, active boolean not null default false)"
                    Database.db << "CREATE TABLE IF NOT EXISTS groups (id int not null auto_increment primary key, name varchar(255) not null unique)"
                    Database.db << "CREATE TABLE IF NOT EXISTS auth_groups (auth_id int not null references auths, group_id int not null references groups, primary key(auth_id, group_id))"
                when :pgsql
                    Database.db << "CREATE TABLE nicks (id serial not null primary key, nick varchar(255) unique not null, username varchar(255), real_name varchar(255), address varchar(255), source varchar(255), connected_at timestamp, connected_to varchar(255), seconds_idle integer, visible boolean not null default false, away boolean not null default false, botnick boolean not null default false)"
                    Database.db << "CREATE INDEX nick_nicks_lower on nicks (lower(nick))"
                    Database.db << "CREATE TABLE channels (id serial not null primary key, name varchar(255) unique not null, password varchar(255), autojoin boolean not null default false, topic varchar(255), quiet boolean not null default false, parked boolean not null default false)"
                    Database.db << "CREATE TABLE auths (id serial not null primary key, password varchar(255), services boolean not null default false, mask varchar(255) unique, authed boolean not null default false, nick_id integer unique references nicks)"
                    Database.db << "CREATE TABLE groups (id serial not null primary key, name varchar(255) unique not null)"
                    Database.db << "CREATE TABLE channel_modes (id serial not null primary key, mode varchar(255) not null, channel_id integer unique not null references channels)"
                    Database.db << "CREATE TABLE configs (id serial not null primary key, name varchar(255) unique not null, value text)"
                    Database.db << "CREATE TABLE nick_channels (channel_id integer not null references channels, nick_id integer not null references nicks, primary key(nick_id, channel_id))"
                    Database.db << "CREATE TABLE nick_modes (id serial not null primary key, mode varchar(255) not null, nick_id integer not null references nicks, channel_id integer references channels, unique (nick_id, channel_id))"
                    Database.db << "CREATE TABLE servers (id serial not null primary key, host varchar(255) not null, port integer not null default 6667, priority integer not null default 0, connected boolean not null default false, unique (host, port))"
                    Database.db << "CREATE TABLE signatures (id serial not null primary key, signature varchar(255) not null, params varchar(255), group_id integer default null references groups, method varchar(255) not null, plugin varchar(255) not null, description varchar(255), requirement varchar(255) default 'both' not null)"
                    Database.db << "CREATE TABLE settings (id serial not null primary key, name varchar(255) unique not null, value varchar(255))"
                    Database.db << "CREATE TABLE triggers (id serial not null primary key, trigger varchar(255) unique not null, active boolean not null default false)"
                    Database.db << "CREATE TABLE auth_groups (auth_id integer not null references auths, group_id integer not null references groups, primary key (auth_id, group_id))"
                when :sqlite
                    Database.db << "CREATE TABLE if not exists nicks (id integer PRIMARY KEY AUTOINCREMENT, nick string UNIQUE NOT NULL COLLATE NOCASE, username string, real_name string, address string, source string, connected_at timestamp, connected_to string, seconds_idle integer, visible boolean NOT NULL DEFAULT 'f', away boolean NOT NULL DEFAULT 'f', botnick boolean NOT NULL DEFAULT 'f')"
                    Database.db << "CREATE TABLE if not exists channels (id integer PRIMARY KEY AUTOINCREMENT, name string UNIQUE NOT NULL COLLATE NOCASE, password string, autojoin boolean NOT NULL DEFAULT 'f', topic string, quiet boolean NOT NULL DEFAULT 'f', parked boolean NOT NULL DEFAULT 'f')"
                    Database.db << "CREATE TABLE if not exists auths (id integer PRIMARY KEY AUTOINCREMENT, password string, services boolean NOT NULL DEFAULT 'f', mask string UNIQUE, authed boolean NOT NULL DEFAULT 'f', nick_id integer UNIQUE REFERENCES nicks)"
                    Database.db << "CREATE TABLE if not exists channel_modes (id integer PRIMARY KEY AUTOINCREMENT, mode string NOT NULL, channel_id integer UNIQUE NOT NULL REFERENCES channels)"
                    Database.db << "CREATE TABLE if not exists configs (id integer PRIMARY KEY AUTOINCREMENT, name string UNIQUE NOT NULL, value string)"
                    Database.db << "CREATE TABLE if not exists nick_channels (channel_id integer NOT NULL REFERENCES channels, nick_id integer NOT NULL REFERENCES nicks, primary key (channel_id, nick_id))"
                    Database.db << "CREATE TABLE if not exists nick_modes (id integer PRIMARY KEY AUTOINCREMENT, mode string NOT NULL, nick_id integer NOT NULL REFERENCES nicks, channel_id integer REFERENCES channels)"
                    Database.db << "CREATE UNIQUE INDEX if not exists nick_modes_nick_id_channel_id_index ON nick_modes (nick_id, channel_id)"
                    Database.db << "CREATE TABLE if not exists servers (id integer primary key autoincrement, host string NOT NULL, port integer NOT NULL DEFAULT 6667, priority integer NOT NULL DEFAULT 0, connected boolean NOT NULL DEFAULT 'f')"
                    Database.db << "CREATE UNIQUE INDEX if not exists servers_host_port_index on servers (host, port)"
                    Database.db << "CREATE TABLE if not exists settings (id integer PRIMARY KEY AUTOINCREMENT, name string UNIQUE NOT NULL, value text)"
                    Database.db << "CREATE TABLE if not exists signatures (id integer PRIMARY KEY AUTOINCREMENT, signature string NOT NULL UNIQUE, params string, group_id integer DEFAULT NULL REFERENCES groups, method string NOT NULL, plugin string NOT NULL, description varchar(255), requirement varchar(255) not null default 'both')"
                    Database.db << "CREATE TABLE if not exists triggers (id integer PRIMARY KEY AUTOINCREMENT, trigger string UNIQUE NOT NULL, active boolean NOT NULL DEFAULT 'f')"            
                    Database.db << "CREATE TABLE if not exists groups (id integer PRIMARY KEY AUTOINCREMENT, name string UNIQUE NOT NULL COLLATE NOCASE)"
                    Database.db << "CREATE TABLE if not exists auth_groups(auth_id integer REFERENCES auths, group_id integer REFERENCES groups)"
            end
        end
    
    end

end