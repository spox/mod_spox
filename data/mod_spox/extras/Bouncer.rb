class Bouncer < ModSpox::Plugin
    
    include Models
    
    def initialize(pipeline)
        super
        admin = Group.find_or_create(:name => 'bouncer')
        Signature.find_or_create(:signature => 'bouncer port ?(\d+)?', :plugin => name, :method => 'port',
            :group_id => admin.pk, :description => 'Show or set bouncer port').params = [:port]
        Signature.find_or_create(:signature => 'bouncer (start|stop|restart)', :plugin => name, :method => 'do_service',
            :group_id => admin.pk, :description => 'Start or stop the bouncer').params = [:action]
        Signature.find_or_create(:signature => 'bouncer status', :plugin => name, :method => 'status',
            :group_id => admin.pk, :description => 'Show current bouncer status')
        Signature.find_or_create(:signature => 'bouncer disconnect', :plugin => name, :method => 'disconnect',
            :group_id => admin.pk, :description => 'Disconnect all users connected to bouncer')
        Signature.find_or_create(:signature => 'bouncer clients', :plugin => name, :method => 'clients',
            :group_id => admin.pk, :description => 'List clients connected to bouncer')
        @pipeline.hook(self, :get_msgs, :Incoming)
        @listener = nil
        @clients = []
        @socket = nil
        @processor = nil
        @to_server = Queue.new
        if(Config[:bouncer_port])
            start_listener
        end
    end
    
    def get_msgs(message)
        unless(@clients.empty?)
        Logger.log("BOUNCER: Sending to #{@clients.size} clients")
            @clients.each do |client|
                begin
                    if(message.raw_content.is_a?(Array))
                        message.raw_content.each do |m|
                            client[:connection].puts(m + "\n")
                        end
                    else
                        client[:connection].puts(message.raw_content + "\n")
                    end
                rescue Object => boom
                    client[:thread].kill if client[:thread].alive?
                    @clients.delete(client)
                end
            end
        end
    end
    
    def port(message, params)
        unless(params[:port])
            if(Config[:bouncer_port])
                reply message.replyto, "Bouncer is currently listening on port: #{Config[:bouncer_port]}"
            else
                reply message.replyto, "\2Warning:\2 Listening port is not currently set for bouncer"
            end
        else
            Config[:bouncer_port] = params[:port].to_i
            reply message.replyto, "Bouncer will now listen on port: #{params[:port].to_i}"
            restart_listener
        end
    end
    
    def do_service(message, params)
        if(params[:action] == 'start')
            if(listening?)
                reply message.replyto, "\2Error:\2 Bouncer is already running"
            else
                start_listener
                reply message.replyto, "Bouncer has been started"
            end
        elsif(params[:action] == 'stop')
            if(listening?)
                stop_listener
                reply message.replyto, "Bouncer has been stopped"
            else
                reply message.replyto, "\2Error:\2 Bouncer is not currently running"
            end
        elsif(params[:action] == 'restart')
            stop_listener
            start_listener
            reply message.replyto, "Bouncer has been restarted"
        end
    end
    
    def disconnect(message, params)
        unless(@clients.empty?)
            @clients.each do |socket|
                socket[:connection].close
                @clients.delete(socket)
            end
            reply message.replyto, "Bouncer has disconnected all clients"
        else
            reply message.replyto, "\2Error:\2 No clients connected to bouncer"
        end
    end
    
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
                        Logger.log("BOUNCER: New connection established on bouncer")
                        @clients << {
                                    :connection => new_con, 
                                    :thread => Thread.new(new_con) do | con |
                                        begin
                                        Logger.log("CONNECTION: #{con}")
                                        until(con.closed?)
                                            Logger.log("WAITING FOR STUFF ON :#{con}")
                                            Kernel.select([con], nil, nil, nil)
                                            Logger.log("Woken up and ready to read")
                                            string = con.gets
                                            Logger.log("BOUNCER GOT MESSAGE: #{string}")
                                            if(string.empty?)
                                                raise Exception.new("EMPTY STRING")
                                            else
                                                @to_server << {:message => string, :socket => con}
                                            end
                                        end
                                        rescue Object => boom
                                        Logger.log("THREAD BOUNCER ERROR: #{boom}")
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
            Logger.log("Error: Bouncer was not started. Failed to find set port number")
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
                Logger.log("Processing message: #{info[:message]}")
                if(info[:message] =~ /^USER\s/i)
                    initialize_connection(info[:socket])
                else
                    @pipeline << Messages::Outgoing::Raw.new(info[:message])
                end
            end
        rescue Object => boom
            Logger.log("BOUNCER ERROR: #{boom}")
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