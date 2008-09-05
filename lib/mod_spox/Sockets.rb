['ipaddr',
 'mod_spox/Bot',
 'mod_spox/Pipeline',
 'mod_spox/MessageFactory',
 'mod_spox/Socket'
].each{|f| require f}

module ModSpox

    class DCCSocket < TCPSocket
    end

    class Sockets

        def initialize(bot)
            @bot = bot
            @reactor = IO::Reactor.new
            @irc_socket = nil
            @dcc_sockets = []
            @mapped_sockets = {}
            @read_sockets = []
            @read_thread = nil
            @pipeline = bot.pipeline
            @factory = bot.factory
            @pipeline.hook(self, :check_dcc, :Incoming_Privmsg)
            @pipeline.hook(self, :return_socket, :Internal_DCCRequest)
            @kill = false
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
                    ip = IPAddr.new($1.to_i, Object::Socket::AF_INET).to_s
                    port = $2.to_i
                    build_connection(ip, port, message.source)
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

        # TODO: make this do stuff

        def shutdown
        end

        private

        # ip:: IP address to connect to
        # port:: Port to connect to
        # nick:: Nick this connection is associated with
        # Builds a DCC connection to given location
        def build_connection(ip, port, nick)
            begin
                socket = DCCSocket.new(ip, port)
                Logger.log("DCC CONNECTED!")
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
                        Logger.log("Waiting for some input")
                        result = Kernel.select(@read_sockets, nil, nil, nil)
                        for sock in result[0] do
                            if(sock.is_a?(DCCSocket))
                                Logger.log("Found a DCCer: #{sock}")
                                string = sock.gets
                                if(sock.closed? || string.nil?)
                                    sock.close
                                    close_dcc(sock)
                                    Logger.log("DCC Socket has been closed: #{sock}")
                                else
                                    @pipeline << Messages::Incoming::Privmsg.new(string, @mapped_sockets[sock.object_id][:nick], "::#{sock.object_id}::", string)
                                end
                            else
                                Logger.log("Reading stuff from: #{sock}")
                                @irc_socket.read
                            end
                        end
                    end
                end
                Logger.log('Reader thread for sockets has been started')
            end
        end

    end
end