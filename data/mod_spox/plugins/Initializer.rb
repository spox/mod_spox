class Initializer < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        @pipeline.hook(self, :connect, :Internal_BotInitialized)
        @pipeline.hook(self, :send_info, :Internal_Connected)
        @pipeline.hook(self, :reconnect, :Internal_ConnectionFailed)
        @pipeline.hook(self, :reconnect, :Internal_Disconnected)
        @servers = Array.new
    end
    
    # message:: ModSpox::Messages::Internal::BotInitialized
    # Instructs bot to connect to server
    def connect(message)
        populate_servers if @servers.empty?
        s = @servers.pop
        @pipeline << Messages::Internal::EstablishConnection.new(s.host, s.port)
    end
    
    # message:: ModSpox::Messages::Internal::Connected
    # Send bot information to server when connection is established
    def send_info(message)
        @pipeline << Messages::Outgoing::Nick.new(Models::Config[:bot_nick])
        @pipeline << Messages::Outgoing::User.new(Models::Config[:bot_username], Models::Config[:bot_realname], 8)    
    end
    
    # message:: ModSpox::Messages::Internal::ConnectionFailed or ModSpox::Messages::Internal::Disconnected
    # Reconnect to server on disconnection or connection failure
    def reconnect(message)
        @pipeline << Messages::Internal::TimerAdd.new(self, Models::Config[:reconnect_wait].to_i, nil, true){ connect(nil) }
    end
    
    private
    
    def populate_servers
        Models::Server.order(:priority.DESC).each{|s|
            @servers << s
        }
    end

end