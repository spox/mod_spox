require 'openssl'

## config stuffs: port

class Bouncer < ModSpox::Plugin

    # Setup our plugin
    def initialize(pipeline)
        super
        bounce = Group.find_or_create(:name => 'bouncer')
        add_sig(:sig => 'bouncer port( (\d+))?', :method => :set_port, :group => bounce, :desc => 'Show or set bouncer port', :params => [:port])
        add_sig(:sig => 'bouncer (start|stop|restart)', :method => :do_service, :group => bounce, :desc => 'Start, stop, or restart bouncer', :params => [:action])
        add_sig(:sig => 'bouncer status', :method => :status, :group => bounce, :desc => 'Show current bouncer status')
        add_sig(:sig => 'bouncer disconnect', :method => :do_disconnect, :group => bounce, :desc => 'Disconnect all connected clients')
        add_sig(:sig => 'bouncer clients', :method => :clients, :group => bounce, :desc => 'List clients connected to bouncer')
        add_sig(:sig => 'bouncer generate cert', :method => :certgen, :group => bounce, :desc => 'Generate new certification')
        @pipeline.hook(self, :get_msgs, :Incoming)
        @spockets = Spockets::Spockets.new
        @listener_thread = nil
        @listener_socket = nil
        @clients = {}
        Helpers.load_message(:outgoing, :Raw)
        Helpers.load_message(:internal, :Incoming)
        start_listener unless port.nil?
    end

    # Clean up our socket stuffs
    def destroy
        stop_listener
        disconnect
    end

    # m:: message
    # params:: parameters
    # Set/show current listening port
    def set_port(m, params)
        begin
            if(params[:port])
                params[:port] = params[:port].to_i
                port(params[:port])
                information m.replyto, "Bouncer port has been updated to: #{params[:port] == 0 ? 'disabled' : params[:port].to_s}"
                warning m.replyto, 'Bouncer must be restarted for port to be changed' if running?
            else
                if(port)
                    information m.replyto, "Bouncer is set to listen on port: #{port}"
                else
                    warning m.replyto, "Bouncer port has not been set"
                end
            end
        rescue Object => boom
            error m.replyto, "Failed to update bouncer port. Reason: #{boom}"
        end
    end
    
    # message:: ModSpox::Messages::Incoming types
    # Get all incoming messages to pass on to clients
    def get_msgs(message)
        unless(@clients.empty?)
            Logger.info("Bouncer has #{@clients.size} clients to send a message to")
            @clients.keys.each do |client|
                begin
                    output = message.raw_content.is_a?(Array) ? message.raw_content.join("\n") : message.raw_content + "\n"
                    client.puts(output)
                rescue Object => boom
                    Logger.warn("Bouncer encountered unexpected error. Disconnecting client. #{boom}")
                    disconnect(client)
                end
            end
        end
    end

    # m:: message
    # params:: parameters
    # Start/stop/restart bouncer
    def do_service(m, params)
        begin
            case params[:action]
            when 'start'
                if(running?)
                    error m.replyto, 'Bouncer is already running'
                else
                    start_listener
                    information m.replyto, 'Bouncer has been started'
                end
            when 'stop'
                if(running?)
                    stop_listener
                    information m.replyto, 'Bouncer has been stopped'
                else
                    error m.replyto, 'Bouncer is not currently running'
                end
            when 'restart'
                stop_listener
                start_listener
                information m.replyto, 'Bouncer has been restarted'
            end
        rescue Object => boom
            error m.replyto, "Error was encountered during #{params[:action]} process. (#{boom})"
        end
    end

    # m:: message
    # params:: parameters
    # Disconnect all clients from bouncer
    # TODO: add individual disconnects
    def do_disconnect(m, params)
        unless(@clients.empty?)
            disconnect
            information m.replyto, 'All clients have been disconnected'
        else
            warning m.replyto, 'No clients are connected to bouncer'
        end
    end

    # m:: message
    # params:: parameters
    # Display current bot status
    def status(m, params)
        information m.replyto, "Status: #{running? ? 'listening' : 'stopped'}"
    end
    
    # m:: message
    # params:: parameters
    # Generate a new certificate
    def certgen(m, params)
        begin
            create_certs
            information m.replyto, 'New certificate has been generated'
        rescue Object
            error m.replyto, "Failed to create new certificate: #{boom}"
        end
    end

    private

    # Generates an OpenSSL::SSL::SSLContext
    def generate_ctx
        c = Models::Setting.filter(:name => 'bouncer_ssl').first
        sc = nil
        if(c)
            cert = c.value
            sc = OpenSSL::SSL::SSLContext.new
            sc.key = OpenSSL::PKey::RSA.new(cert[:key])
            sc.cert = OpenSSL::X509::Certificate.new(cert[:cert])
        else
            create_certs
            sc = generate_ctx
        end
        return sc
    end

    # Generates and stores new key and certificate
    def create_certs
        Logger.info('Generating key/cert pair for bouncer SSL')
        key = OpenSSL::PKey::RSA.new(2048)
        cert = OpenSSL::X509::Certificate.new
        cert.not_before = Time.now
        cert.not_after = Time.now + 99999999
        cert.public_key = key.public_key
        cert.sign(key, OpenSSL::Digest::SHA1.new)
        c = Models::Setting.find_or_create(:name => 'bouncer_ssl')
        c.value = {:cert => cert.to_s, :key => key.to_s}
        c.save
    end

    # Starts the listener for new connections
    def start_listener
        raise 'Port has not been set' if port.nil?
        begin
            @socket = OpenSSL::SSL::SSLServer.new(TCPServer.new(port), generate_ctx)
            @listener = Thread.new do
                until(@socket.closed?) do
                    begin
                        new_con = @socket.accept
                        add_client(new_con)
                    rescue Object => boom
                        Logger.warn "Bouncer listener encountered an error: #{boom}"
                        retry
                    end
                end
                @listener = nil
            end
        rescue Object => boom
            Logger.error "Bouncer listener encountered an error: #{boom}"
            raise boom
        end
    end

    # socket:: SSLSocket
    # Adds a new client to the bouncer
    def add_client(socket)
        @clients[socket] = {:nick => false, :user => false, :init => false}
        @spockets.add(socket) do |string|
            deliver_message(string, socket)
        end
    end

    # string:: outgoing string
    # socket:: SSLSocket that sent the string
    # Delivers messages from clients to the IRC
    # server
    def deliver_message(string, socket)
        Logger.info("Processing bouncer message: #{string} for socket: #{socket}")
        begin
            unless(@clients[socket][:init])
                part = string.slice(0,5)
                Logger.info "Part we extracted: #{part}|"
                @clients[socket][:nick] = true if part == 'NICK '
                @clients[socket][:user] = true if part == 'USER '
                if(@clients[socket][:nick] && @clients[socket][:user])
                    initialize_connection(socket)
                    @clients[socket][:init] = true
                else
                    Logger.warn("Got part: #{part}. Not init yet")
                end
            else
                filter(string, socket)
            end
        rescue Object => boom
            Logger.error("Bouncer received message but failed to pass it on. Error: #{boom} Message: #{string}")
        end
    end

    # Stops the listener
    def stop_listener
        @socket.close
        @listener.kill unless @listener.nil?
        @listener = nil
        @socket = nil
    end

    # socket:: SSLSocket
    # Disconnect given socket or all sockets
    def disconnect(socket=nil)
        sockets = socket.nil? ? @clients.keys : [socket]
        sockets.each do |sock|
            @spockets.remove(sock)
            sock.close
            @clients.delete(sock)
        end
    end

    # Returns if the listener is running
    def running?
        return !@listener.nil?
    end
    
    # connection:: SSLSocket
    # Sends initialization information to client. Basically a
    # 001 welcome message and JOINs for any channels the bot is in
    def initialize_connection(connection)
        # send channel info and such to client
        connection.puts(":localhost 001 #{me.nick} :Welcome to the network #{me.source}\n")
        me.channels.each do |channel|
            connection.puts(":#{me.source} JOIN :#{channel.name}\n")
        end
    end

    # num:: integer
    # Set/show port number for listener
    def port(num=nil)
        if(num.nil?)
            conf = Models::Config.filter(:name => 'bouncer_port').first
            return conf ? conf.value : nil
        else
            if(num == 0)
                Models::Config.filter(:name => 'bouncer_port').destroy
            else
                raise 'Invalid port number' if num < 1 || num > 65535
                conf = Models::Config.find_or_create(:name => 'bouncer_port')
                conf.value = num
                conf.save
            end
        end
    end

    # string:: Outgoing string
    # socket:: SSLSocket
    # Filter outgoing string to be delivered to IRC server. This
    # is used to stop excessive WHO/PING type messages from flooding
    # the server and getting the bot kicked.
    def filter(string, socket)
        @pipeline << Messages::Outgoing::Raw.new(string)
        @pipeline << Messages::Internal::Incoming.new(":#{me.source} #{string}")
    end

    class Filter
        def Filter.all(string, socket)
        end

        def Filter.who(string, socket)
        end

        def Filter.quit(string, socket)
        end

        def Filter.ping(string, socket)
        end
    end
    
end