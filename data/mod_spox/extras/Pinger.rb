class Pinger < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        add_sig(:sig => 'ping', :method => :ping)
    end
    
    def ping(message, params)
        reply message.replyto, "#{message.source.nick}: pong"
    end
end