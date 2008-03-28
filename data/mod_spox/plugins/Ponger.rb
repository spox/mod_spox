class Ponger < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        @pipeline.hook(self, :ping, :Incoming_Ping)
    end
    
    # message:: ModSpox::Messages::Incoming::Ping
    # Sends responding pongs to server pings
    def ping(message)
        @pipeline << Messages::Outgoing::Pong.new(message.server, message.string)
    end

end