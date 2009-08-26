['ipaddr',
 'iconv',
 'mod_spox/Bot',
 'mod_spox/Pipeline',
 'mod_spox/MessageFactory',
 'mod_spox/Socket',
 'mod_spox/messages/internal/DCCSocket',
 'mod_spox/messages/outgoing/Privmsg'
].each{|f| require f}

require 'spockets'

module ModSpox

    class Sockets

        attr_reader :irc_socket

        def initialize(bot)
            @bot = bot
            @irc_socket = nil
            @dcc_sockets = []
            @mapped_sockets = {}
            @spockets = Spockets::Spockets.new(:pool => bot.pool)
            @listening_dcc = []
            @dcc_ports = {:start => 49152, :end => 65535}
            @dcc_wait = 30
            @pipeline = bot.pipeline
            @factory = bot.factory
            @pipeline.hook(self, :check_dcc, ModSpox::Messages::Incoming::Privmsg)
            @pipeline.hook(self, :return_socket, ModSpox::Messages::Internal::DCCRequest)
            @pipeline.hook(self, :dcc_listener, ModSpox::Messages::Internal::DCCListener)
            @pipeline.hook(self, :disconnect_irc, ModSpox::Messages::Internal::Disconnected)
            @pipeline.hook(self, :queue_messages, ModSpox::Messages::Internal::QueueSocket)
            @pipeline.hook(self, :unqueue_messages, ModSpox::Messages::Internal::UnqueueSocket)
            @queues = {:irc => Queue.new, :dcc => Queue.new}
            @queue_messages = false
        end

        # server:: IRC server string
        # port:: IRC port
        # Connect to the given IRC server
        def irc_connect(server=nil, port=nil)
            if(@irc_socket.nil?)
                @irc_socket = Socket.new(@bot, server, port)
                @irc_socket.connect
                @spockets.add(@irc_socket.socket){|string| process_irc_string(string)}
                @spockets.on_close(@irc_socket.socket){ irc_reconnect }
            else
                irc_reconnect
            end
        end
        
        def irc_reconnect
            unless(@irc_socket.nil?)
                disconnect_irc
                @spockets.remove(@irc_socket.socket) if @spockets.include?(@irc_socket)
                @irc_socket.shutdown(true)
                @spockets.add(@irc_socket.socket){|string| process_irc_string(string)}
            else
                irc_connect
            end
        end

        def <<(message)
            if(message =~ /::(\S+)::\s:(.+)$/)
                id = $1.to_i
                message = $2 + "\r\n"
                sock_info = @mapped_sockets[id]
                sock_info[:socket] << message
            else
                @irc_socket << message
            end
        end
        
        def prioritize_message(target, message)
            @irc_socket.prioritize_message(target, message)
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
                        Logger.warn("Error: #{message.source.nick} is attempting to establish DCC connection without permission.")
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
                    Logger.info("New DCC socket created for #{message.nick.nick} has connected from: #{cip}:#{cport}")
                    @dcc_sockets << client
                    @mapped_sockets[client.object_id] = {:socket => client, :nick => message.nick}
                    @spockets.add(socket){|string| process_dcc_string(string, socket)}
                rescue Timeout::Error => boom
                    Logger.warn("Timeout reached waiting for #{message.nick.nick} to connect to DCC socket. Closing.")
                    client.close
                rescue Object => boom
                    Logger.warn("Unknown error encountered while building DCC listener for: #{message.nick.nick}. Error: #{boom}")
                    client.close
                ensure
                    socket.close
                end
            end
        end

        # Shuts down all active sockets
        def shutdown
            @spockets.clear
            @irc_socket.shutdown
            @dcc_sockets.each do |sock|
                close_dcc(sock)
            end
        end

        def disconnect_irc(m=nil)
            @spockets.remove(@irc_socket.socket) if @spockets.include?(@irc_socket.socket)
        end
        
        def unqueue_messages(m)
            @queue_messages = false
            flush_queues
        end
        
        def queue_messages(m)
            @queue_messages = true
        end

        private

        # ip:: IP address to connect to
        # port:: Port to connect to
        # nick:: Nick this connection is associated with
        # Builds a DCC connection to given location
        def build_connection(ip, port, nick)
            begin
                socket = TCPSocket.new(ip, port)
                @spockets.add(socket){|string| process_dcc_string(string, socket)}
                @mapped_sockets[socket.object_id] = {:socket => socket, :nick => nick}
                @dcc_sockets << socket
                Logger.info("New DCC connection established to #{nick.nick} on #{ip}:#{port}")
            rescue Object => boom
                Logger.warn("DCC connection to #{nick.nick} on #{ip}:#{port} failed. #{boom}")
            end
        end

        def close_dcc(sock)
            @spockets.remove(sock)
            @dcc_sockets.delete(sock)
            @mapped_sockets.delete(sock.object_id)
        end

        def process_irc_string(string)
            if(@queue_messages)
                @queues[:irc] << string
            else
                @irc_socket.process(string)
            end
        end
        
        def process_dcc_string(string, socket)
            if(@queue_messages)
                @queues[:dcc] = {:string => string, :socket => socket}
            else
                Logger.info("DCC >> #{string}")
                if(socket.closed? || string.nil?)
                    socket.close
                    close_dcc(socket)
                else
                    @pipeline << Messages::Incoming::Privmsg.new(string, @mapped_sockets[socket.object_id][:nick], "::#{sock.object_id}::", string)
                end
            end
        end
        
        def flush_queues
            until(@queues[:irc].empty?)
                process_irc_string(@queues[:irc].pop)
            end
            until(@queues[:dcc].empty?)
                con = @queues[:dcc].pop
                process_dcc_string(con[:string], con[:socket])
            end
        end

    end
end