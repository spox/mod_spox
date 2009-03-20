class Quitter < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        add_sig(:sig => 'quit(\s.+)?', :method => :quit, :group => Models::Group.filter(:name => 'admin').first, :params => [:channel, :message])
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # Instructs the bot to shutdown    
    def quit(message, params)
        @pipeline << Messages::Internal::HaltBot.new
    end
end