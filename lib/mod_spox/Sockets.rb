['ipaddr',
 'iconv',
 'mod_spox/Bot',
 'mod_spox/Pipeline',
 'mod_spox/MessageFactory',
 'mod_spox/Socket'
].each{|f| require f}

module ModSpox

    class Sockets

        def initialize(bot)
            @bot = bot
            @irc_socket = nil
            @dcc_sockets = []
            @mapped_sockets = {}
            @read_sockets = []
            @listening_dcc = []
            @dcc_ports = {:start => 49152, :end => 65535}
            @dcc_wait = 30
            @read_thread = nil
            @pipeline = bot.pipeline
            @factory = bot.factory
            @pipeline.hook(self, :check_dcc, :Incoming_Privmsg)
            @pipeline.hook(self, :return_socket, :Internal_DCCRequest)
            @pipeline.hook(self, :dcc_listener, :Internal_DCCListener)
            @kill = false
            @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
        end

        # server:: IRC server string
        # port:: IRC port
        # Connect to the given IRC server
        def irc_connect(server, port)
            @irc_socket = Socket.new(@bot, server, port)
            @irc_socket.connect
            @read_sockets << @irc_socket.socket
            restart_reader
        end

        def <<(message)
            if(message =~ /::(\S+)::\s:(.+)$/)
                id = $1.to_i
                message = $2 + "\r\n"
                sock_info = @mapped_sockets[id]
                socket = sock_info[:socket]
            else
                socket = @irc_socket
            end
            socket << message
        end

        # message:: ModSpox::Messages::Incoming::Privmsg
        # Checks if incoming message is a request to
        # start a DCC chat session and builds the connection
        def check_dcc(message)
            if(message.is_ctcp? && message.ctcp_type == 'DCC')
                if(message.message =~ /^CHAT chat (\S+) (\S+)/)
                    if(message.source.in_group?('dcc') || message.source.in_group?('admin'))
                        ip = IPAddr.new($1.to_i, Object::Socket::AF_INET).to_s
                        port = $2.to_i
                        build_connection(ip, port, message.source)
                    else
                        Logger.log("Error: #{message.source.nick} is attempting to establish DCC connection without permission.")
                    end
                end
            end
        end

        # message:: ModSpox::Messages::Internal::DCCRequest
        # Returns the DCC Socket requested in a ModSpox::Messages::Internal::DCCSocket
        # message.
        def return_socket(message)
            socket = nick = nil
            if(@mapped_socks.has_key?(message.socket_id))
                socket = @mapped_socks[message.socket_id][:socket]
                nick = @mapped_socks[message.socket_id][:nick]
            end
            @pipeline << Messages::Internal::DCCSocket.new(message.socket_id, nick, socket)
        end

        # message:: ModSpox::Messages::Internal::DCCListener
        # Sets up a new socket for a user to connect to. Helpful
        # if the user wants a DCC chat session but is firewalled
        def dcc_listener(message)
            Thread.new do
                me = Models::Nick.filter(:botnick => true).first
                return if me.nil?
                port = rand(@dcc_ports[:end] - @dcc_ports[:start]) + @dcc_ports[:start]
                socket = Object::Socket.new(Object::Socket::AF_INET, Object::Socket::SOCK_STREAM, 0)
                addr = Object::Socket.pack_sockaddr_in(port, me.address)
                socket.bind(addr)
                client = nil
                addrinfo = nil
                cport = nil
                cip = nil
                begin
                    Timeout::timeout(@dcc_wait) do
                        @pipeline << Messages::Outgoing::Privmsg.new(message.nick, "CHAT chat #{IPAddr.new(me.address).to_i} #{port}", false, true, 'DCC')
                        socket.listen(5)
                        client, addrinfo = socket.accept
                        cport, cip = Object::Socket.unpack_sockaddr_in(addrinfo)
                    end
                    Logger.log("New DCC socket created for #{message.nick.nick} has connected from: #{cip}:#{cport}")
                    stop_reader
                    @dcc_sockets << client
                    @mapped_sockets[client.object_id] = {:socket => client, :nick => message.nick}
                    @read_sockets << client
                    start_reader
                rescue Timeout::Error => boom
                    Logger.log("Timeout reached waiting for #{message.nick.nick} to connect to DCC socket. Closing.")
                    client.close
                rescue Object => boom
                    Logger.log("Unknown error encountered while building DCC listener for: #{message.nick.nick}. Error: #{boom}")
                    client.close
                ensure
                    socket.close
                end
            end
        end

        # Shuts down all active sockets
        def shutdown
            stop_reader
            @irc_socket.shutdown
            @dcc_sockets.each do |sock|
                close_dcc(sock)
            end
        end

        private

        # ip:: IP address to connect to
        # port:: Port to connect to
        # nick:: Nick this connection is associated with
        # Builds a DCC connection to given location
        def build_connection(ip, port, nick)
            begin
                socket = TCPSocket.new(ip, port)
                stop_reader
                @read_sockets << socket
                @mapped_sockets[socket.object_id] = {:socket => socket, :nick => nick}
                @dcc_sockets << socket
                start_reader
                Logger.log("New DCC connection established to #{nick.nick} on #{ip}:#{port}")
            rescue Object => boom
                Logger.log("DCC connection to #{nick.nick} on #{ip}:#{port} failed. #{boom}")
            end
        end

        def close_dcc(sock)
            @read_sockets.delete(sock)
            @dcc_sockets.delete(sock)
            @mapped_sockets.delete(sock.object_id)
        end

        def stop_reader
            Logger.log('Stopping reader thread for sockets')
            if(!@thread_read.nil? && @thread_read.alive?)
                @kill = true
                @thread_read.join(0.2)
                @thread_read.kill if @thread_read.alive?
                @kill = false
            end
            Logger.log('Reader thread for sockets has been stopped')
        end

        def restart_reader
            stop_reader
            start_reader
        end


        def start_reader
            Logger.log('Starting reader thread for sockets')
            if(!@thread_read.nil? && @thread_read.alive?)
                Logger.log('ERROR: Cannot start reader. Already running.')
            else
                @thread_read = Thread.new do
                    until @kill do
                        begin
                            result = Kernel.select(@read_sockets, nil, nil, nil)
                            for sock in result[0] do
                                unless(sock == @irc_socket.socket)
                                    tainted_string = sock.gets
                                    string = @ic.iconv(tainted_string + ' ')[0..-2]
                                    Logger.log("DCC >> #{string}")
                                    if(sock.closed? || string.nil?)
                                        sock.close
                                        close_dcc(sock)
                                    else
                                        @pipeline << Messages::Incoming::Privmsg.new(string, @mapped_sockets[sock.object_id][:nick], "::#{sock.object_id}::", string)
                                    end
                                else
                                    @irc_socket.read
                                end
                            end
                        rescue Object => boom
                            Logger.log("Socket error detected: #{boom}\n#{boom.backtrace}")
                        end
                    end
                end
                Logger.log('Reader thread for sockets has been started')
            end
        end

    end
end