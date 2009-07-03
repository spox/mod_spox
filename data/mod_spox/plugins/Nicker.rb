require 'mod_spox/messages/outgoing/Nick'
class Nicker < ModSpox::Plugin
    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'nick (\S+)', :method => :change_nick, :group => admin, :params => [:nick])
    end
    
    # message:: ModSpox::Messages::Incoming::Privmsg
    # Join the given channel
    def change_nick(message, params)
        @pipeline << Messages::Outgoing::Nick.new(params[:nick])
    end
end