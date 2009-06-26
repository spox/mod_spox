['iconv',
 'mod_spox/Logger',
 'mod_spox/Exceptions',
 'mod_spox/messages/Messages',
 'mod_spox/models/Models',
 'mod_spox/Pipeline',
 'mod_spox/PriorityQueue'].each{|f|require f}

module ModSpox

    class Socket

        attr_reader :sent
        attr_reader :received
        attr_reader :burst
        attr_reader :burst_in
        attr_reader :delay
        attr_reader :server
        attr_reader :port
        attr_reader :socket
        attr_reader :connected_at

        # factory:: MessageFactory to parse messages
        # server:: Server to connect to
        # port:: Port number to connect to
        # delay:: Number of seconds to delay between bursts
        # burst_in:: Number of seconds allowed to burst
        # burst:: Number of lines allowed to be sent within the burst_in time limit
        # Create a new Socket
        def initialize(bot, server=nil, port=nil, delay=2, burst_in=2, burst=4)
            @pool = bot.pool
            @factory = bot.factory
            @pipeline = bot.pipeline
            @dcc = bot.dcc_sockets
            @server = server
            @port = port
            @sent = 0
            @received = 0
            @delay = delay.to_f > 0 ? delay.to_f : 2.0
            @burst = burst.to_i > 0 ? burst.to_i : 4
            @burst_in = 2
            @kill = false
            @time_check = nil
            @check_burst = 0
            @pause = false
            @sendq = PriorityQueue.new
            @lock = Mutex.new
            @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
            @connected_at = nil
            @empty_lines = 0
            @max_empty = 5
            @servers = Array.new
            @connect_locker = Mutex.new
        end

        # Connects to the IRC server
        def connect
            return unless @connect_locker.try_lock
            begin
                populate_servers if @servers.empty?
                s = @servers.pop
                @server = s.host
                @port = s.port.to_i
                Logger.info("Establishing connection to #{@server}:#{@port}")
                @socket = TCPSocket.new(@server, @port)
                @socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_KEEPALIVE, true)
                @empty_lines = 0
                s.connected = true
                s.save
                @connected_at = Time.now
                @pipeline << Messages::Internal::Connected.new(@server, @port)
            ensure
                @connect_locker.unlock
            end
        end

        # new_delay:: Seconds to delay between bursts
        # Resets the delay
        def delay=(new_delay)
            raise Exceptions::InvalidValue('Send delay must be a positive number') unless new_delay.to_f > 0
            @delay = new_delay.to_f
        end

        # new_burst:: Number of lines allowed in burst
        # Resets the burst
        def burst=(new_burst)
            raise Exceptions::InvalidValue('Burst value must be a positive number') unless new_burst.to_i > 0
            @burst = new_burst
        end

        # new_burst_in:: Number of seconds allowed to burst
        # Resets the burst_in
        def burst_in=(new_burst_in)
            raise Exceptions::InvalidValue('Burst in value must be positive') unless new_burst_in.to_i > 0
            @burst_in = new_burst_in
        end

        # message:: String to send to server
        # Sends a string to the IRC server
        def puts(message)
            write(message)
        end

        # message:: String to send to server
        # Sends a string to the IRC server
        def write(message)
            return if message.nil?
            begin
                @socket.puts(message + "\n")
                @socket.flush
                Logger.info("<< #{message}")
                @last_send = Time.new
                @sent += 1
                @check_burst += 1
                @time_check = Time.now.to_i if @time_check.nil?
            rescue Object => boom
                Logger.warn("Failed to write message to server. #{boom}")
                @pipeline << Messages::Internal::Disconnected.new
                raise Exceptions::Disconnected.new
            end
        end
        
        # string:: string to be processed
        # Process a string
        def process(string)
            string.strip!
            Logger.info(">> #{string}")
            if(string[0,5] == 'ERROR')
                @pipeline << Messages::Internal::Disconnected.new
                raise Exceptions::Disconnected.new
            end
            @received += 1
            @factory << string
        end

        # message:: String to be sent to server
        # Queues a message up to be sent to the IRC server
        def <<(message)
            @sendq.direct_queue(message)
            @pool.process{ processor }
        end
        
        # target:: Target for outgoing message
        # message:: Message to send
        # This queues a message to be sent out of a prioritized
        # queue. This allows for even message distribution rather
        # than only on target at a time being flooded.
        def prioritize_message(target, message)
            @sendq.priority_queue(target, message)
            @pool.process{ processor }
        end

        # Starts the thread for sending messages to the server
        def processor
            return unless @lock.try_lock
            did_write = false
            begin
                loop do
                    write(@sendq.pop)
                    did_write = true
                    if((Time.now.to_i - @time_check) > @burst_in)
                        @time_check = nil
                        @check_burst = 0
                    elsif((Time.now.to_i - @time_check) <= @burst_in && @check_burst >= @burst)
                        Logger.warn("Burst limit hit. Output paused for: #{@delay} seconds")
                        sleep(@delay)
                        @time_check = nil
                        @check_burst = 0
                    end
                end
            rescue Exceptions::EmptyQueue => boom
                Logger.info('Socket reached an empty queue.')
            ensure
                @lock.unlock
                @pool.process{ processor } if did_write
            end
        end

        # restart:: Reconnect after closing connection
        # Closes connection to IRC server
        def shutdown(restart=false)
            @socket.close unless @socket.nil? || @socket.closed?
            @kill = true
            server = Models::Server.find_or_create(:host => @server, :port => @port)
            server.connected = false
            server.save
            sleep(0.1)
            connect if restart
        end

        private

        def populate_servers
            Models::Server.reverse_order(:priority).each{|s|
                @servers << s
            }
        end

    end

end