require 'splib'
require 'socket'
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
            self.port = args[:port] if args[:port]
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

        # Is socket connected?
        def connected?
            @socket && @socket.connected?
        end

        # d:: delay
        # Set the burst delay
        def burst_delay=(d)
            @args[:delay] = d
        end

        # i:: seconds to check for burst
        # Set allowed seconds for burst
        def burst_in=(i)
            @args[:burst_in] = i
        end

        # l:: number of lines
        # Set number of lines allowed during burst
        def burst_lines=(l)
            @args[:burst_lines] = l
        end

        # Delay when burst limit reached
        def burst_delay
            @args[:delay]
        end

        # Length of time to watch for exceeding burst
        def burst_in
            @args[:burst_in]
        end

        # Number of lines allowed in burst
        def burst_lines
            @args[:burst_lines]
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
            start
            return true
        end

        # message:: Message to send
        # Send a message to the server
        def write(message)
            Logger.info("<< #{message}")
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
                Logger.debug "Socket thread is now running"
                begin
                    until(@stop) do
                        m = @queue.pop
                        next unless m
                        write(m)
                        t = Time.now.to_i - @time_check
                        if(t > @args[:burst_in])
                            @time_check = nil
                            @burst_check = 0
                        elsif(t <= @args[:burst_in] && @burst_check >= @args[:burst_lines])
                            Logger.info "Burst limit reached. Sleeping for: #{@args[:delay]} seconds"
                            sleep(@args[:delay])
                            @time_check = nil
                            @burst_check = 0
                        end
                    end
                rescue => e
                    Logger.debug "Socket thread encountered an error: #{e}"
                    Logger.debug "Restarting socket thread"
                    retry
                end
                Logger.debug "Socket thread is now complete"
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
