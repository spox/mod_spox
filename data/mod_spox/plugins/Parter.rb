class Parter < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        Models::Signature.find_or_create(:signature => 'part (\S+)', :plugin => name, :method => 'part', :group_id => admin.pk).params = [:channel]
        Models::Signature.find_or_create(:signature => 'part', :plugin => name, :method => 'direct_part', :group_id => admin.pk)
    end
    
    # message:: ModSpox::Messages::Incoming::Privmsg
    # Bot will part from given channel
    def part(message, params)
        @pipeline << Messages::Outgoing::Part.new(params[:channel])
    end
    
    # message:: ModSpox::Messages::Incoming::Privmsg
    # Bot will part from channel command is issued within
    def direct_part(message, params)
        @pipeline << Messages::Outgoing::Part.new(message.target)
    end

end