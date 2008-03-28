class Quitter < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        Models::Signature.find_or_create(:signature => 'quit\s(.*)', :plugin => name, :method => 'quit',
            :group_id => Models::Group.filter(:name => 'admin').first.pk).params = [:channel, :message]
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # Instructs the bot to shutdown    
    def quit(message, params)
        @pipeline << Messages::Internal::HaltBot.new
    end
end