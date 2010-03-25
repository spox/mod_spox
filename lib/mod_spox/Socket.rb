require 'splib'
Splib.load :Monitor, :PriorityQueue

module ModSpox
    # IRC Socket
    class Socket
        # Raw socket
        attr_reader :socket
        # Message queue
        attr_reader :queue

        # args:: Hash of arguments
        #   {:server, :port, :delay, :burst_lines, :burst_in}
        # Create a new IRC socket
        def initialize(args={})
            @args = {:server => nil, :port => nil, :delay => 2.0, :burst_lines => 4,
                :burst_in => 2}.merge(args)
            @socket = nil
            @connect_lock = Splib::Monitor.new
            @queue = Splib::PriorityQueue.new
            @pause = false
            @stop = false
            @last_send = nil
            @time_check = nil
            @burst_check = 0
            @thread = nil
        end

        # s:: Server name
        # Set server name
        def server=(s)
            @args[:server] = s
        end

        # p:: Server port
        # Set server port
        def port=(p)
            p = p.to_i
            raise ArgumentError.new('Port must be > 0') if p < 1
            @args[:port] = p
        end

        # Server name
        def server
            @args[:server]
        end

        # Server port
        def port
            @args[:port]
        end

        # Connect to IRC server
        def connect
            unless(@args[:server] && @args[:port])
                raise ArgumentError.new('Server and port must be set')
            end
            return unless @connect_lock.try_lock
            begin
                @socket = TCPSocket.new(@args[:server], @args[:port])
                @socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_KEEPALIVE, true)
            ensure
                @connect_lock.unlock
            end
            return true
        end

        # message:: Message to send
        # Send a message to the server
        def write(message)
            @socket.puts("#{message}\n")
            @socket.flush
            @last_send = Time.now
            @burst_check += 1
            @time_check = Time.now.to_i if @time_check.nil?
        end

        # Start worker to send output
        def start
            raise 'Already running' if @thread && @thread.alive?
            @thread = Thread.new do
                until(@stop) do
                    m = sendq.pop
                    next unless m
                    write(m)
                    t = Time.now.to_i - @time_check
                    if(t > @burst_in)
                        @time_check = nil
                        @burst_check = 0
                    elsif(t <= @burst_in && @burst_check >= @burst_lines)
                        sleep(@delay)
                        @time_check = nil
                        @burst_check = 0
                    end
                end
            end
            true
        end

        # Stop worker
        def stop
            @stop = true
            @queue << nil
            @thread.join
            @thread = nil
            true
        end
        
    end
end
