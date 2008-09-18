['mod_spox/Logger',
 'mod_spox/Pool',
 'mod_spox/Exceptions',
 'mod_spox/messages/Messages',
 'mod_spox/models/Models',
 'mod_spox/Pipeline'].each{|f|require f}

module ModSpox

    class Socket < Pool

        attr_reader :sent
        attr_reader :received
        attr_reader :burst
        attr_reader :burst_in
        attr_reader :delay
        attr_reader :server
        attr_reader :port
        attr_reader :socket

        # factory:: MessageFactory to parse messages
        # server:: Server to connect to
        # port:: Port number to connect to
        # delay:: Number of seconds to delay between bursts
        # burst_in:: Number of seconds allowed to burst
        # burst:: Number of lines allowed to be sent within the burst_in time limit
        # Create a new Socket
        def initialize(bot, server, port, delay=2, burst_in=2, burst=4)
            super()
            @factory = bot.factory
            @pipeline = bot.pipeline
            @dcc = bot.dcc_sockets
            @server = server
            @port = port.to_i
            @sent = 0
            @received = 0
            @delay = delay.to_f > 0 ? delay.to_f : 2.0
            @burst = burst.to_i > 0 ? burst.to_i : 4
            @burst_in = 2
            @kill = false
            @time_check = nil
            @check_burst = 0
            @pause = false
            @sendq = Queue.new
            @lock = Mutex.new
            start_pool
        end

        # Connects to the IRC server
        def connect
            Logger.log("Establishing connection to #{@server}:#{@port}", 10)
            @socket = TCPSocket.new(@server, @port)
            server = Models::Server.find_or_create(:host => @server, :port => @port)
            server.connected = true
            server.save
            Logger.log("Created new send queue: #{@sendq}", 10)
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
            @socket.puts(message + "\n")
            Logger.log("<< #{message}", 5)
            @last_send = Time.new
            @sent += 1
            @check_burst += 1
            @time_check = Time.now.to_i if @time_check.nil?
        end

        # Retrieves a string from the server
        def read
            message = @socket.gets
            if(message.nil? || @socket.closed?) # || message =~ /^ERROR/)
                @pipeline << Messages::Internal::Disconnected.new
                shutdown
                server = Models::Server.find_or_create(:host => @server, :port => @port)
                server.connected = false
                server.save
            elsif(message.length > 0)
                Logger.log(">> #{message}", 5)
                @received += 1
                message.strip!
                @factory << message
            end
        end

        # message:: String to be sent to server
        # Queues a message up to be sent to the IRC server
        def <<(message)
            @sendq << message
            @queue << Proc.new{ processor }
        end

        # Starts the thread for sending messages to the server
        def processor
            @lock.synchronize do
                write(@sendq.pop(true))
                if((Time.now.to_i - @time_check) > @burst_in)
                    @time_check = nil
                    @check_burst = 0
                elsif((Time.now.to_i - @time_check) <= @burst_in && @check_burst >= @burst)
                    Logger.log("Burst limit hit. Output paused for: #{@delay} seconds", 70)
                    sleep(@delay)
                    @time_check = nil
                    @check_burst = 0
                end
            end
        end

        # restart:: Reconnect after closing connection
        # Closes connection to IRC server
        def shutdown(restart=false)
            @socket.close unless @socket.closed?
            @kill = true
            server = Models::Server.find_or_create(:host => @server, :port => @port)
            server.connected = false
            server.save
            sleep(0.1)
            connect if restart
        end

    end

end