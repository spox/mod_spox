require 'openssl'

## config stuffs: port

class Bouncer < ModSpox::Plugin

    def initialize(pipeline)
        super
        bounce = Group.find_or_create(:name => 'bouncer')
        add_sig(:sig => 'bouncer port( (\d+))?', :method => :set_port, :group => bounce, :desc => 'Show or set bouncer port', :params => [:port])
        add_sig(:sig => 'bouncer (start|stop|restart)', :method => :do_service, :group => bounce, :desc => 'Start, stop, or restart bouncer', :params => [:action])
        add_sig(:sig => 'bouncer status', :method => :status, :group => bounce, :desc => 'Show current bouncer status')
        add_sig(:sig => 'bouncer disconnect', :method => :do_disconnect, :group => bounce, :desc => 'Disconnect all connected clients')
        add_sig(:sig => 'bouncer clients', :method => :clients, :group => bounce, :desc => 'List clients connected to bouncer')
        @pipeline.hook(self, :get_msgs, :Incoming)
        @spockets = Spockets::Spockets.new
        @listener_thread = nil
        @listener_socket = nil
        @clients = []
        Helpers.load_message(:outgoing, :Raw)
        start_listener unless port.nil?
    end

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

    def do_disconnect(m, params)
        unless(@clients.empty?)
            disconnect
            information m.replyto, 'All clients have been disconnected'
        else
            warning m.replyto, 'No clients are connected to bouncer'
        end
    end
    
    def status(m, params)
        information m.replyto, "Status: #{running? ? 'listening' : 'stopped'}"
    end

    private

    def start_listener
        raise 'Port has not been set' if port.nil?
        begin
            @socket = OpenSSL::SSL::SSLServer.new('0.0.0.0', port)
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
    
    def add_client(socket)
        @clients[socket] = {:nick => false, :user => false, :init => false}
        @spockets.add(socket) do |string|
            deliver_message(string, socket)
        end
    end

    def deliver_message(string, socket)
        Logger.info("Processing bouncer message: #{string} for socket: #{socket}")
        unless(@clients[socket][:init])
            part = string.slice(0,5)
            @clients[socket][:nick] = true if part == 'NICK '
            @clients[socket][:user] = true if part == 'USER '
            if(@client[socket][:nick] && @client[socket][:user])
                initialize_connection(socket)
                @clients[socket][:init] = true 
            end
        else
            @pipeline << Messages::Outgoing::Raw.new(string)
        end
    end
    
    def stop_listener
        @socket.close
        @listener.kill unless @listener.nil?
        @listener = nil
        @socket = nil
    end

    def disconnect(socket=nil)
        sockets = socket.nil? ? @clients.keys : [socket]
        sockets.each do |sock|
            @spockets.remove(sock)
            sock.close
            @clients.delete(sock)
        end
    end
    
    def running?
        return !@listener.nil?
    end
    
    def initialize_connection(connection)
        # send channel info and such to client
        connection.puts(":localhost 001 #{me.nick} :Welcome to the network #{me.source}\n")
        Models::Channel.filter(:parked => true).each do |channel|
            connection.puts(":#{me.source} JOIN :#{channel.name}\n")
        end
    end

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
    
end