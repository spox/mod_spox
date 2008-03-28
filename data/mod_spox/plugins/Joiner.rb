class Joiner < ModSpox::Plugin
    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        Models::Signature.find_or_create(:signature => 'join (\S+)', :plugin => name, :method => 'join', :group_id => admin.pk).params = [:channel]
    end
    
    # message:: ModSpox::Messages::Incoming::Privmsg
    # Join the given channel
    def join(message, params)
        @pipeline << Messages::Outgoing::Join.new(params[:channel])
    end
end