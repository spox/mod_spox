require 'actionpool'
require 'actiontimer'
require 'pipeliner'
require 'spockets'
require 'baseirc'
require 'messagefactory'
require 'pstore'
require 'mod_spox'
require 'mod_spox/Socket'
require 'mod_spox/Outputter'
require 'mod_spox/Logger'
require 'mod_spox/PluginManager'
require 'mod_spox/Messages'

module ModSpox

    class ConfigurationMissing < RuntimeError
    end

    # Give us a nice easy way to globally access the
    # directory we are supposed to store our data in
    class << self
        # dir:: Directory path
        # Set directory to store files
        def config_dir=(dir)
            @@config_dir = dir
        end
        # Directory to store files. If it has not been set,
        # it will default to '/tmp'
        def config_dir
            if(class_variable_defined?(:@@config_dir))
                @@config_dir
            else
                '/tmp'
            end
        end
    end

    # IRC Bot
    class Bot

        attr_reader :pool
        attr_reader :timer
        attr_reader :pipeline
        attr_reader :irc
        attr_reader :plugin_manager
        attr_reader :socket

        # :db_path:: Path to database file
        # Create a new bot instance
        def initialize
            @halt = false
            @socket = nil
            @con_info = {}
            @start_time = Time.now
            @pool = ActionPool::Pool.new(:a_to => 10)
            @timer = ActionTimer::Timer.new(:pool => @pool)
            @pipeline = Pipeliner::Pipeline.new(:pool => @pool)
            @outputter = Outputter.new
            @outputter.start
            @irc = BaseIRC::IRC.new(@outputter.queue)
            @sockets = Spockets::Spockets.new
            @factory = MessageFactory::Factory.new
            @plugin_manager = PluginManager.new(self)
            @monitor = Splib::Monitor.new
        end

        def start
            unless(Thread.current == Thread.main)
                raise 'This should only be called by the main thread'
            end
            cycle_connect
            Logger.debug 'Bot has been started. Main thread taking a nap until halt time.'
            @monitor.wait_until{ @halt }
            Logger.debug 'Main thread back in action. Time to shut this thing down'
        end

        def stop
            @halt = true
            @pool.shutdown
            close_socket
            @monitor.broadcast
        end

        def connect_to(server, port=6667)
            close_socket
            Logger.debug "Attempting connection to: #{server}:#{port}"
            @socket = Socket.new(:server => server, :port => port, :delay => @con_info[:burst_delay],
                :burst_lines => @con_info[:burst_lines], :burst_in => @con_info[:burst_in])
            @socket.connect
            register_socket
            Logger.debug "Established connection to: #{server}:#{port}"
            @pipeline << Messages::Connected.new
        end

        def cycle_connect
            load_servers if @con_info.empty? || @con_info[:servers].empty?
            if(@con_info[:servers].empty?)
                raise ConfigurationMissing.new 'No servers found in connection configuration'
            end
            srv = @con_info[:servers].pop
            connect_to(srv[:server], srv[:port])
        end

        def close_socket
            return unless @socket
            if(@socket.connected?)
                @sockets.remove(@socket.socket)
            end
            @socket.stop
        end

        private
        
        # Gets everything setup to start processing messages. This is
        # pretty much what makes the bot go.
        def register_socket
            @sockets.add(@socket.socket) do |m|
                Logger.info(">> #{m.strip}")
                m = @factory.process(m)
                unless(m)
                    @pipeline << m
                end
            end
            @outputter.queue = @socket.queue
            @sockets.on_close(@socket.socket){|s| cycle_connect }
        end

        def load_servers
            unless(File.exists?("#{ModSpox.config_dir}/connection.pstore"))
                raise ConfigurationMissing.new 'No configuration files found'
            end
            store = PStore.new("#{ModSpox.config_dir}/connection.pstore")
            @con_info.clear
            store.transaction do
                @con_info[:burst_in] = store[:burst_in]
                @con_info[:burst_delay] = store[:burst_delay]
                @con_info[:burst_lines] = store[:burst_lines]
                @con_info[:servers] = store[:servers]
            end
        end
    end
end
