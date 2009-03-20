require 'openssl'

class Bouncer < ModSpox::Plugin

    def initialize(pipeline)
        super
        bounce = Group.find_or_create(:name => 'bouncer')
        add_sig(:sig => 'bouncer port( (\d+))?', :method => :port, :group => bounce, :desc => 'Show or set bouncer port',
            :params => [:port])
        add_sig(:sig => 'bouncer (start|stop|restart)', :method => :do_service, :group => bounce, :desc => 'Start, stop, or restart bouncer')
        add_sig(:sig => 'bouncer status', :method => :status, :group => bounce, :desc => 'Show current bouncer status')
        add_sig(:sig => 'bouncer disconnect', :method => :disconnect, :group => bounce, :desc => 'Disconnect all connected clients')
        add_sig(:sig => 'bouncer clients'< :method => :clients, :group => bounce, :desc => 'List clients connected to bouncer')
        @pipeline.hook(self, :get_msgs, :Incoming)
        @listener = nil
        @clients = []
        @socket = nil
        @processor = nil
        @to_server = Queue.new
        start_listener if Models::Config.filter(:name => 'bouncer_port').count > 0
    end
    
    def get_msgs(message)
        unless(@clients.empty?)
            Logger.info("Bouncer has #{@clients.size} clients to send a message to")
            @clients.each do |client|
                begin
                    output = message.raw_content.is_a?(Array) ? message.raw_content.join("\n") : message.raw_content + "\n"
                    client[:connection].puts(output)
                rescue Object => boom
                    Logger.warn("Bouncer encountered unexpected error. Disconnecting client. #{boom}")
                    client[:thread].kill if client[:thread].alive?
                    @clients.delete(client)
                end
            end
        end
    end
    
    def port(m, params)
        if(params[:port])
            if(Models::Config.filter(:name => 'bouncer_port').count > 0)
                reply m.replyto, "Bouncer port is set to: #{Models::Config.filter(:name => 'bouncer_port').first.value
            else
                error m.replyo, 'No port has been set for bouncer'
            end
        else
            parmas[:port].strip!
            c = Models::Config.find_or_create(:name => 'bouncer_port')
            c.value = params[:port]
            c.save
            information m.replyto, "Bouncer port is not set to: #{params[:port]}"
        end
    end
    
    def do_service(m, params)
        begin
            case params[:action]
            when 'start'
                if(listening?)
                    error m.replyto, 'Bouncer is already running'
                else
                    start_listener
                    information m.replyto, 'Bouncer has been started'
                end
            when 'stop'
                if(listening?)
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

    def disconnect(m, params)
        unless(@clients.empty?)
            @clients.each do |client|
                client[:connection].close unless client[:connection].closed?
                @clients.delete(client)
            end
            information m.replyto, 'All clients have been disconnected'
        else
            warning m.replyto, 'No clients are connected to bouncer'
        end
    end
    
    def status(m, params)
        warning m.replyto, 'not implemented'
    end

    private
    
    def start_listener
        port = Models::Config.filter(:name => 'bouncer_port').first
        raise 'Port has not been set' unless port
        port = port.value.to_i
        @socket = OpenSSL::SSL::SSLServer.new(port)
        @listener = Thread.new do
            until(@socket.closed?)
                begin
                    new_con = @socket.accept_nonblock
                    add_client(new_con)
                rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                        IO.select([@socket])
                        retry
                rescue Object => boom
                    Logger.warn "Bouncer listener encountered an error: #{boom}"
                end
            end
        end
    end
    
    def add_client
    end

class Bouncer < ModSpox::Plugin
    
    def status(message, params)
    end
    
    private
    
    def start_listener
        port = Config[:bouncer_port]
        if(port)
            @socket = TCPServer.new(port)
            @listener = Thread.new do
                until(@socket.closed?)
                    begin
                        new_con = @socket.accept_nonblock
                        Logger.info("BOUNCER: New connection established on bouncer")
                        @clients << {
                                    :connection => new_con, 
                                    :thread => Thread.new(new_con) do | con |
                                        begin
                                        Logger.info("CONNECTION: #{con}")
                                        until(con.closed?)
                                            Logger.info("WAITING FOR STUFF ON :#{con}")
                                            Kernel.select([con], nil, nil, nil)
                                            Logger.info("Woken up and ready to read")
                                            string = con.gets
                                            Logger.info("BOUNCER GOT MESSAGE: #{string}")
                                            if(string.empty?)
                                                raise Exception.new("EMPTY STRING")
                                            else
                                                @to_server << {:message => string, :socket => con}
                                            end
                                        end
                                        rescue Object => boom
                                        Logger.warn("THREAD BOUNCER ERROR: #{boom}")
                                        end
                                        end
                                    }
                    rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                        IO.select([@socket])
                        retry
                    end
                end
                @listener = nil
            end
            start_processor
        else
            Logger.warn("Error: Bouncer was not started. Failed to find set port number")
        end
    end
    
    def stop_listener
        @socket.close
        @listener.kill unless @listener.nil?
        @listener = nil
        @to_server.clear
        @processor.kill if !@processor.nil? && @processor.alive?
        @processor = nil
    end
    
    def start_processor
        @processor.kill if !@processor.nil? && @processor.alive?
        @processor = Thread.new do
        begin
            while(@listener) do
                info = @to_server.pop
                Logger.info("Processing message: #{info[:message]}")
                if(info[:message] =~ /^USER\s/i)
                    initialize_connection(info[:socket])
                else
                    @pipeline << Messages::Outgoing::Raw.new(info[:message])
                end
            end
        rescue Object => boom
            Logger.warn("BOUNCER ERROR: #{boom}")
            unless(@clients.empty?)
                @clients.each do |socket|
                    socket[:connection].close
                    @clients.delete(socket)
                end
            end
        end
        end
    end
    
    def listening?
        return !@listener.nil?
    end
    
    def initialize_connection(connection)
        # send channel info and such to client
        connection.puts(":localhost 001 #{me.nick} :Welcome to the network #{me.source}\n")
        Models::Channel.filter(:parked => true).each do |channel|
            connection.puts(":#{me.source} JOIN :#{channel.name}\n")
        end
    end
    
end