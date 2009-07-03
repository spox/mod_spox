require 'mod_spox/messages/outgoing/Privmsg'
class Talk < ModSpox::Plugin

    include Models
    
    def initialize(pipeline)
        super
        group = Group.find_or_create(:name => 'talk')
        add_sig(:sig => 'say (\S+) (.+)', :method => :talk, :group => group, :desc => 'Make bot speak given text to target', :req => 'private', :params => [:target, :text])
        add_sig(:sig => 'action (\S+) (.+)', :method => :action, :group => group, :desc => 'Make bot perform action for target', :req => 'private', :params => [:target, :text])
    end
    
    def talk(message, params)
        send_p(message, params)
    end
    
    def action(message, params)
        send_p(message, params, true)
    end
    
    private
    
    def send_p(message, params, action=false)
        target = Helpers.find_model(params[:target], false)
        if(target.nil?)
            reply message.replyto, "\2Error:\2 Failed to locate target: #{params[:target]}"
        else
            @pipeline << Messages::Outgoing::Privmsg.new(target, params[:text], action)
        end
    end

end