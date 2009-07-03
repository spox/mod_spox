require 'mod_spox/messages/outgoing/Join'
require 'mod_spox/messages/outgoing/Who'

class Joiner < ModSpox::Plugin
    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'join (\S+)', :method => :join, :group => admin, :params => [:channel])
        @pipeline.hook(self, :send_who, :Incoming_Join)
    end
    
    # message:: ModSpox::Messages::Incoming::Privmsg
    # Join the given channel
    def join(message, params)
        @pipeline << Messages::Outgoing::Join.new(params[:channel])
    end
    
    # message:: ModSpox::Messages::Incoming::Join
    # Send a WHO request for channel on join
    def send_who(message)
        @pipeline << ModSpox::Messages::Outgoing::Who.new(message.channel.name) if message.nick == me
    end
end