['mod_spox/messages/internal/EstablishConnection',
 'mod_spox/messages/internal/Reconnect',
 'mod_spox/messages/outgoing/Nick',
 'mod_spox/messages/outgoing/User'].each{|f| require f}
class Initializer < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        @pipeline.hook(self, :connect, ModSpox::Messages::Internal::BotInitialized)
        @pipeline.hook(self, :send_info, ModSpox::Messages::Internal::Connected)
        @pipeline.hook(self, :reconnect, ModSpox::Messages::Internal::ConnectionFailed)
        @pipeline.hook(self, :reconnect, ModSpox::Messages::Internal::Disconnected)
        @servers = Array.new
    end
    
    # message:: ModSpox::Messages::Internal::BotInitialized
    # Instructs bot to connect to server
    def connect(message)
        @pipeline << Messages::Internal::EstablishConnection.new
    end
    
    # message:: ModSpox::Messages::Internal::Connected
    # Send bot information to server when connection is established
    def send_info(message)
        @pipeline << Messages::Outgoing::Nick.new(Models::Config.val(:bot_nick))
        @pipeline << Messages::Outgoing::User.new(Models::Config.val(:bot_username), Models::Config.val(:bot_realname), 8)
    end
    
    # message:: ModSpox::Messages::Internal::ConnectionFailed or ModSpox::Messages::Internal::Disconnected
    # Reconnect to server on disconnection or connection failure
    def reconnect(message)
        @pipeline << Messages::Internal::Reconnect.new
    end

end