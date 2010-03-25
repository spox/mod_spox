require 'actionpool'
require 'actiontimer'
require 'pipeliner'
require 'spockets'
require 'baseirc'
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
        # :db_path:: Path to database file
        # Create a new bot instance
        def initialize(db_path)
            @db = initialize_db(db_path)
            @start_time = Time.now
            @pool = ActionPool::Pool.new(:a_to => 10)
            @timer = ActionTimer::Timer.new(:pool => @pool)
            @pipeline = Pipeliner::Pipeline.new(:pool => @pool)
            @socket = nil
            @outputter = Outputter.new(@socket.queue)
            @irc = BaseIRC::IRC.new(@outputter.queue)
            @sockets = Spockets::Spockets.new
            @factory = MessageFactory::Factory.new
            @halt = false
            @monitor = Splib::Monitor.new
        end

        def start
            unless(Thread.current == Thread.main)
                raise 'This should only be called by the main thread'
            end
            do_setup
            @monitor.wait_until{ @halt }
        end

        def stop
            @halt = true
            @monitor.broadcast
            @pool.shutdown
        end

        def connect_to(server, port=6667)
            close_socket
            @socket = Socket.new(:server => server, :port => port)
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
    end
end
