['mod_spox/Logger',
 'mod_spox/Sockets',
 'mod_spox/Pipeline',
 'mod_spox/PluginManager',
 'mod_spox/MessageFactory',
 'mod_spox/BaseConfig',
 'mod_spox/models/Models',
 'mod_spox/Helpers',
 'mod_spox/Timer',
 'mod_spox/messages/internal/BotInitialized',
 'mod_spox/messages/internal/Shutdown',
 'mod_spox/messages/internal/ConnectionFailed',
 'mod_spox/messages/internal/StatusResponse',
 'mod_spox/messages/internal/NickResponse',
 'actionpool',
 'actiontimer'].each{|f|require f}

module ModSpox

    class Bot

        # bot timer
        attr_reader :timer
        
        # thread pool
        attr_reader :pool

        # message pipeline
        attr_reader :pipeline

        # plugin manager
        attr_reader :plugin_manager

        # message factory
        attr_reader :factory

        # DCC sockets
        attr_reader :dcc_sockets

        # Create a Bot
        def initialize
            unless(ModSpox.logto.nil?)
                logger = ::Logger.new(ModSpox.logto, 'daily')
                Logger.initialize(logger, ModSpox.loglevel)
            end
            clean_models
            @servers = Array.new
            @channels = Array.new
            @start_time = Time.now
            @pool = ActionPool::Pool.new(10, 100, 60, nil, logger)
            @pipeline = Pipeline.new(@pool)
            @timer = Timer.new(ActionTimer::Timer.new(@pool, logger), @pipeline)
            @config = BaseConfig.new(BotConfig[:userconfigpath])
            @factory = MessageFactory.new(@pipeline, @pool)
            @socket = nil
            @plugin_manager = PluginManager.new(@pipeline)
            if(@config[:plugin_upgrade] == 'yes')
                @plugin_manager.upgrade_plugins
                Logger.info('Main bot thread is now sleeping for 10 seconds to allow upgrade to conclude')
                sleep(10)
                Logger.info('Main bot thread sleep completed. Continuing loading.')
            end
            @config[:plugin_upgrade] = 'no'
            @config.write_configuration
            @shutdown = false
            @socket = Sockets.new(self)
            @nick = nil
            @thread = Thread.current
            @lock = Mutex.new
            @waiter = ConditionVariable.new
            hook_pipeline
        end

        # Run the bot
        def run
            trap('SIGTERM'){ Logger.warn("Caught SIGTERM"); halt }
            trap('SIGKILL'){ Logger.warn("Caught SIGKILL"); halt }
            trap('SIGINT'){ Logger.warn("Caught SIGINT"); halt }
            trap('SIGQUIT'){ Logger.warn("Caught SIGQUIT"); halt }
            until @shutdown do
                @pipeline << Messages::Internal::BotInitialized.new
                begin
                    @lock.synchronize do
                        Logger.info('Putting main execution thread to sleep until shutdown')
                        @waiter.wait(@lock)
                        Logger.info('Main execution thread has been restored.')
                    end
                rescue Object => boom
                    Logger.fatal("Caught exception: #{boom}")
                ensure
                    shutdown
                end
            end
        end

        # Shut the bot down
        def shutdown
            @shutdown = true
            Logger.info('Shutdown sequence initiated')
            @plugin_manager.destroy_plugins
            @timer.stop
            @pipeline << Messages::Internal::Shutdown.new
            sleep(0.1)
            @socket.shutdown unless @socket.nil?
            clean_models
        end

        # Reload the bot (basically a restart)
        def reload
            @lock.synchronize do
                @waiter.signal
            end
        end

        # message:: Messages::Internal::EstablishConnection message
        # Initialize connection to IRC server
        def bot_connect(message)
            Logger.info("Received a connection command")
            begin
                @socket = Sockets.new(self) if @socket.nil?
                @socket.irc_connect(message.server, message.port)
            rescue Object => boom
                Logger.warn("Failed connection to server: #{boom}")
                @pipeline << Messages::Internal::ConnectionFailed.new(@socket.irc_socket.server, @socket.irc_socket.port)
            end
        end

        # message:: Messages::Internal::Reconnect
        # instructs bot to reconnect to IRC server
        def reconnect(message=nil)
            begin
                @plugin_manager.reload_plugins
                @socket.irc_reconnect
            rescue Object => boom
                Logger.warn("Initial reconnect failed. (#{boom}) Starting timed reconnect process.")
                begin
                    @socket.irc_reconnect
                rescue Object => boom
                    Logger.warn("Failed to connect to server. Reason: #{boom}")
                    Logger.warn("Will retry in 20 seconds")
                    sleep(20)
                    retry
                end
            end
        end

        # message:: Messages::Internal::StatusRequest message
        # Returns the current status of the bot
        def status(message)
            @pipeline << Messages::Internal::StatusResponse.new(message.requester, bot_stats)
        end

        # Returns status of the bot in a formatted string
        def bot_stats
            return {:uptime => Helpers::format_seconds(Time.now - @start_time),
                    :plugins => @plugin_manager.plugins.size,
                    :socket_connect => @socket.irc_socket.connected_at,
                    :sent => @socket.irc_socket.sent,
                    :received => @socket.irc_socket.received}
        end

        # Adds hooks to pipeline for processing messages
        def hook_pipeline
            {'ModSpox::Messages::Outgoing::Admin' => :admin, 'ModSpox::Messages::Outgoing::Away' => :away,
             'ModSpox::Messages::Outgoing::ChannelMode' => :channel_mode, 'ModSpox::Messages::Outgoing::Connect' => :connect,
             'ModSpox::Messages::Outgoing::Die' => :die, 'ModSpox::Messages::Outgoing::Info' => :info,
             'ModSpox::Messages::Outgoing::Invite' => :invite, 'ModSpox::Messages::Outgoing::Ison' => :ison,
             'ModSpox::Messages::Outgoing::Join' => :join, 'ModSpox::Messages::Outgoing::Kick' => :kick,
             'ModSpox::Messages::Outgoing::Kill' => :kill, 'ModSpox::Messages::Outgoing::Links' => :links,
             'ModSpox::Messages::Outgoing::List' => :list, 'ModSpox::Messages::Outgoing::Lusers' => :lusers,
             'ModSpox::Messages::Outgoing::Motd' => :motd, 'ModSpox::Messages::Outgoing::Names' => :names,
             'ModSpox::Messages::Outgoing::Nick' => :nick, 'ModSpox::Messages::Outgoing::Notice' => :notice,
             'ModSpox::Messages::Outgoing::Oper' => :oper, 'ModSpox::Messages::Outgoing::Part' => :part,
             'ModSpox::Messages::Outgoing::Pass' => :pass, 'ModSpox::Messages::Outgoing::Ping' => :ping,
             'ModSpox::Messages::Outgoing::Pong' => :pong, 'ModSpox::Messages::Outgoing::Privmsg' => :privmsg,
             'ModSpox::Messages::Outgoing::Quit' => :quit, 'ModSpox::Messages::Outgoing::Rehash' => :rehash,
             'ModSpox::Messages::Outgoing::ServList' => :servlist, 'ModSpox::Messages::Outgoing::Squery' => :squery,
             'ModSpox::Messages::Outgoing::Squit' => :squit, 'ModSpox::Messages::Outgoing::Stats' => :stats,
             'ModSpox::Messages::Outgoing::Summon' => :summon, 'ModSpox::Messages::Outgoing::Time' => :time,
             'ModSpox::Messages::Outgoing::Topic' => :topic, 'ModSpox::Messages::Outgoing::Trace' => :trace,
             'ModSpox::Messages::Outgoing::Unaway' => :unaway, 'ModSpox::Messages::Outgoing::User' => :user,
             'ModSpox::Messages::Outgoing::UserHost' => :userhost, 'ModSpox::Messages::Outgoing::UserMode' => :user_mode,
             'ModSpox::Messages::Outgoing::Users' => :users, 'ModSpox::Messages::Outgoing::Version' => :version,
             'ModSpox::Messages::Outgoing::Who' => :who, 'ModSpox::Messages::Outgoing::WhoWas' => :whowas,
             'ModSpox::Messages::Outgoing::Whois' => :whois, 'ModSpox::Messages::Internal::EstablishConnection' => :bot_connect,
             'ModSpox::Messages::Internal::StatusRequest' => :status, 'ModSpox::Messages::Internal::ChangeNick' => :set_nick,
             'ModSpox::Messages::Internal::NickRequest' => :get_nick, 'ModSpox::Messages::Internal::HaltBot' => :halt,
             'ModSpox::Messages::Internal::Disconnected' => :disconnected, 'ModSpox::Messages::Internal::TimerClear' => :clear_timer,
             'ModSpox::Messages::Outgoing::Raw' => :raw, 'ModSpox::Messages::Internal::Reconnect' => :reconnect,
             'ModSpox::Messages::Incoming::Join' => :check_join, 'ModSpox::Messages::Incoming::Part' => :check_part
             }.each_pair{ |type,method| @pipeline.hook(self, method, type) }
        end

        # message:: Messages::Internal::TimerClear
        # Clear all actions from timer
        def clear_timer(message)
            @timer.clear
        end

        # message:: Messages::Internal::Disconnected
        # Disconnect the bot from the IRC server
        def disconnected(message)
            reload
        end

        # Stop the bot
        def halt(message=nil)
            @shutdown = true
            reload
        end

        # message:: Messages::Internal::ChangeNick message
        # Changes the bot's nick to the given nick
        def set_nick(message)
            @nick = message.new_nick
        end

        # message:: Messages::Internal::NickRequest
        # Sends the bot's nick to plugins
        def get_nick(message)
            @pipeline << Messages::Internal::NickResponse(message.requester, @nick)
        end

        # message:: Messages::Outgoing::Pass message
        # Sends PASS message to server
        def pass(message)
            @socket << "PASS #{message.password}"
        end

        # message:: Messages::Outgoing::Nick message
        # Sends NICK message to server
        def nick(message)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            @socket << "NICK #{nick}"
        end

        # message:: Messages::Outgoing::User message
        # Sends USER message to server
        def user(message)
            @socket << "USER #{message.username} #{message.mode} * :#{message.real_name}"
        end

        # message:: Messages::Outgoing::Oper message
        # Sends Oper message to server
        def oper(message)
            @socket << "OPER #{message.name} #{message.password}"
        end

        # message:: Messages::Outgoing::UserMode message
        # Sends MODE message to server
        def user_mode(message)
            raise Exceptions::InvalidValue.new('Mode must be in the form of: [+-][a-z]+') unless message.mode =~ /^[+\-][a-z]+$/
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            @socket << "MODE #{nick} #{message.mode}"
        end

        # message:: Messages::Outgoing::Quit message
        # Sends QUIT message to server
        def quit(message)
            @socket << "QUIT :#{message.message}"
        end

        # message:: Messages::Outgoing::Squit message
        # Sends SQUIT message to server
        def squit(message)
            @socket << "SQUIT #{message.server} :#{message.comment}"
        end

        # message:: Messages::Outgoing::Join message
        # Sends JOIN message to server
        def join(message)
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "JOIN #{channel} #{message.key}"
        end

        # message:: Messages::Outgoing::Part message
        # Sends PART message to server
        def part(message)
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "PART #{channel} :#{message.reason}"
        end

        # message:: Messages::Outgoing::ChannelMode message
        # Sends MODE message to server
        def channel_mode(message)
            target = message.target
            channel = message.channel
            target = target.nick if target.is_a?(Models::Nick)
            channel = channel.name if channel.is_a?(Models::Channel)
            @socket << "MODE #{channel} #{message.mode} #{target}"
        end

        # message:: Messages::Outgoing::Topic message
        # Sends TOPIC message to server
        def topic(message)
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "TOPIC #{channel} :#{message.topic}"
        end

        # message:: Messages::Outgoing::Names message
        # Sends NAMES message to server
        def names(message)
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "NAMES #{channel} #{message.target}"
        end

        # message:: Messages::Outgoing::List message
        # Sends LIST message to server
        def list(message)
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "LIST #{channel}"
        end

        # message:: Messages::Outgoing::Invite message
        # Sends INVITE message to server
        def invite(message)
            okay_to_send(message.channel)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "INVITE #{nick} #{channel}"
        end

        # message:: Messages::Outgoing::Kick message
        # Sends KICK message to server
        def kick(message)
            okay_to_send(message.channel)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "KICK #{channel} #{nick} :#{message.reason}"
        end

        # message:: Messages::Outgoing::Privmsg message
        # Sends PRIVMSG message to server
        def privmsg(message)
            okay_to_send(message.target)
            target = message.target.name if message.target.is_a?(Models::Channel)
            target = message.target.nick if message.target.is_a?(Models::Nick)
            target = message.target unless target
            messages = message.message.is_a?(Array) ? message.message : [message.message]
            messages.each do |part|
                part.split("\n").each do |content|
                    while(content.size > 400)
                        output = content[0..400]
                        content.slice!(0, 401) #(450, content.size)
                        @socket.prioritize_message(target, "PRIVMSG #{target} :#{message.is_ctcp? ? "\cA#{message.ctcp_type} #{output}\cA" : output}")
                    end
                    @socket.prioritize_message(target, "PRIVMSG #{target} :#{message.is_ctcp? ? "\cA#{message.ctcp_type} #{content}\cA" : content}")
                end
            end
        end

        # message:: Messages::Outgoing::Notice message
        # Sends NOTICE message to server
        def notice(message)
            okay_to_send(message.target)
            target = message.target.name if message.target.is_a?(Models::Channel)
            target = message.target.nick if message.target.is_a?(Models::Nick)
            @socket << "NOTICE #{target} :#{message}"
        end

        # message:: Messages::Outgoing::Motd message
        # Sends MOTD message to server
        def motd(message)
            @socket << "MOTD #{message.target}"
        end

        # message:: Messages::Outgoing::Lusers message
        # Sends LUSERS message to server
        def lusers(message)
            @socket << "LUSERS #{message.mask} #{message.target}"
        end

        # message:: Messages::Outgoing::Version message
        # Sends VERSION message to server
        def version(message)
            @socket << "VERSION #{message.target}"
        end

        # message:: Messages::Outgoing::Stats message
        # Sends STATS message to server
        def stats(message)
            raise Exceptions::InvalidValue.new('Query must be a single character') unless message.query =~ /^[a-z]$/
            @socket << "STATS #{message.query} #{message.target}"
        end

        # message:: Messages::Outgoing::Links message
        # Sends LINKS message to server
        def links(message)
            @socket << "LIST #{message.server} #{message.mask}"
        end

        # message:: Messages::Outgoing::Time message
        # Sends TIME message to server
        def time(message)
            @socket << "TIME #{message.target}"
        end

        # message:: Messages::Outgoing::Connect message
        # Sends CONNECT message to server
        def connect(message)
            @socket << "CONNECT #{message.target_server} #{message.port} #{message.remote_server}"
        end

        # message:: Messages::Outgoing::Trace message
        # Sends TRACE message to server
        def trace(message)
            @socket << "TRACE #{message.target}"
        end

        # message:: Messages::Outgoing::Admin message
        # Sends ADMIN message to server
        def admin(message)
            @socket << "ADMIN #{message.target}"
        end

        # message:: Messages::Outgoing::Info message
        # Sends INFO message to server
        def info(message)
            @socket << "INFO #{message.target}"
        end

        # message:: Messages::Outgoing::ServList message
        # Sends SERVLIST message to server
        def servlist(message)
            @socket << "SERVLIST #{message.mask} #{message.type}"
        end

        # message:: Messages::Outgoing::Squery message
        # Sends SQUERY message to server
        def squery(message)
            @socket << "SQUERY #{message.service_name} #{message.message}"
        end

        # message:: Messages::Outgoing::Who message
        # Sends WHO message to server
        def who(message)
            o = message.only_ops? ? 'o' : ''
            @socket.prioritize_message('*who', "WHO #{message.mask} #{o}")
        end

        # message:: Messages::Outgoing::Whois message
        # Sends WHOIS message to server
        def whois(message)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            @socket.prioritize_message('*whois', "WHOIS #{message.target_server} #{nick}")
        end

        # message:: Messages::Outgoing::WhoWas message
        # Sends WHOWAS message to server
        def whowas(message)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            @socket << "WHOWAS #{message.nick} #{message.count} #{message.target}"
        end

        # message:: Messages::Outgoing::Kill message
        # Sends KILL message to server
        def kill(message)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            @socket << "KILL #{nick} :#{message.comment}"
        end

        # message:: Messages::Outgoing::Ping message
        # Sends PING message to server
        def ping(message)
            @socket << "PING #{message.message}"
        end

        # message:: Messages::Outgoing::Pong message
        # Sends PONG message to server
        def pong(message)
            @socket << "PONG #{message.server} #{message.string.nil? ? '' : ":#{message.string}"}"
        end

        # message:: Messages::Outgoing::Away message
        # Sends AWAY message to server
        def away(message)
            @socket << "AWAY :#{message.message}"
        end

        # message:: Messages::Outgoing::Unaway message
        # Sends AWAY message to server
        def unaway(message)
            @socket << "AWAY"
        end

        # message:: Messages::Outgoing::Rehash message
        # Sends REHASH message to server
        def rehash(message)
            @socket << "REHASH"
        end

        # message:: Messages::Outgoing::Die message
        # Sends DIE message to server
        def die(message)
            @socket << "DIE"
        end

        # message:: Messages::Outgoing::Restart message
        # Sends RESTART message to server
        def restart(message)
            @socket << "RESTART"
        end

        # message:: Messages::Outgoing::Summon message
        # Sends SUMMON message to server
        def summon(message)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            channel = message.channel.is_a?(Models::Channel) ? message.channel.name : message.channel
            @socket << "SUMMON #{nick} #{message.target} #{channel}"
        end

        # message:: Messages::Outgoing::Users message
        # Sends USERS message to server
        def users(message)
            @socket << "USERS #{message.target}"
        end

        def wallops
        end

        # message:: Messages::Outgoing::UserHost message
        # Sends USERHOST message to server
        def userhost(message)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            @socket << "USERHOST #{nick}"
        end

        # message:: Messages::Outgoing::Ison message
        # Sends ISON message to server
        def ison(message)
            nick = message.nick.is_a?(Models::Nick) ? message.nick.nick : message.nick
            @socket << "ISON #{nick}"
        end

        # message:: Messages::Outoing::Raw message
        # Send raw message to server
        def raw(message)
            @socket << message.message
        end

        def check_join(m)
            if(m.nick.botnick)
                @channels << m.channel.name.downcase
            end
        end

        def check_part(m)
            if(m.nick.botnick)
                @channels.delete(m.channel.name.downcase)
            end
        end

        private

        # channel:: channel to check
        # checks if the bot is parked in the given channel
        # and raises an exception (and logs) if the bot
        # is not in the given channel
        def okay_to_send(channel)
            if(channel.is_a?(String) && ['&', '#', '+', '!'].include?(channel.slice(0,1)))
                channel = Helpers.find_model(channel)
            end
            return unless channel.is_a?(Models::Channel)
            # not really needed with filters now enabled
#             if(channel.quiet)
#                 Logger.error("Attempted to send to channel where bot is not allowed to speak: #{channel.name}")
#                 raise Exceptions::QuietChannel.new(channel)
#             end
            unless(in_channel?(channel))
                Logger.error("Attempted to send to channel where bot is not parked: #{channel.name}.")
                raise Exceptions::NotInChannel.new(channel)
            end
        end

        def in_channel?(channel)
            unless(@channels.include?(channel.name.downcase))
                repopulate_channels
                return @channels.include?(channel.name.downcase)
            else
                return true
            end
        end

        def repopulate_channels
            bot = Models::Nick.filter(:botnick => true).first
            raise Exceptions::BotException.new("I DON'T KNOW WHO I AM") unless bot
            @channels.clear
            bot.channels.each{|c| @channels << c.name.downcase}
        end

        # Cleans information from models to avoid
        # stale values
        def clean_models
            Models::NickMode.destroy
            Models::Channel.update(:topic => nil)
            Models::Nick.update(:username => nil, :real_name => nil, :address => nil,
                :source => nil, :connected_at => nil, :connected_to => nil,
                :seconds_idle => nil, :away => false, :visible => false, :botnick => false)
            Models::Auth.update(:authed => false)
            Database.db[:auth_masks_nicks].delete
            Database.db[:nick_channels].delete
        end
    end

end