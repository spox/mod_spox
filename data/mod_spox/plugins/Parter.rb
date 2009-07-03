require 'mod_spox/messages/outgoing/Part'
class Parter < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'part (\S+)', :method => :part, :group => admin, :params => [:channel])
        add_sig(:sig => 'part', :method => :direct_part, :group => admin)
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