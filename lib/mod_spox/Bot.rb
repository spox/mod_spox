require 'actionpool'
require 'actiontimer'
require 'pipeliner'
require 'spockets'
require 'baseirc'
require 'pstore'
require 'mod_spox'
require 'mod_spox/Socket'
require 'mod_spox/Outputter'

module ModSpox

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
            @outputter = Outputter.new(@socket.queue)
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
            do_setup
            @socket.connect
            @monitor.wait_until{ @halt }
        end

        def stop
            @halt = true
            @monitor.broadcast
            @pool.shutdown
        end

        def connect_to(server, port=6667)
            close_socket
            @socket = Socket.new(:server => server, :port => port, :delay => @con_info[:burst_delay],
                :burst_lines => @con_info[:burst_lines], :burst_in => @con_info[:burst_in])
        end

        def cycle_connect
            load_servers if @con_info[:servers].empty?
            srv = @con_info[:servers].pop
            connect_to(srv[:server], srv[:port])
        end

        private
        
        # Gets everything setup to start processing messages. This is
        # pretty much what makes the bot go.
        def do_setup
            raise '' if @socket.nil?
            @sockets.clear
            @sockets.add(@socket.socket) do |m|
                m = @factory.process(m)
                unless(m)
                    @pipeline << m
                end
            end
        end

        def load_servers
            store = PStore.new("#{ModSpox.config_dir}/connection.pstore")
            store.transaction do
                @con_info = store.dup
            end
        end
    end
end
