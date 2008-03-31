class Pinger < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        Models::Signature.find_or_create(:signature => 'ping', :plugin => name, :method => 'ping')
    end
    
    def ping(message, params)
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "#{message.source.nick}: pong")
    end
end