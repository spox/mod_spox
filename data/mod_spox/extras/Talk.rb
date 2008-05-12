class Talk < ModSpox::Plugin

    include Models
    
    def initialize(pipeline)
        super
        group = Group.find_or_create(:name => 'talk')
        Signature.find_or_create(:signature => 'say (\S+) (.+)', :plugin => name, :method => 'talk', :group_id => group.pk,
            :description => 'Make bot speak given text to target', :requirement => 'private').params = [:target, :text]
        Signature.find_or_create(:signature => 'action (\S+) (.+)', :plugin => name, :method => 'action', :group_id => group.pk,
            :description => 'Make bot perform action for target', :requirement => 'private').params = [:target, :text]
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
            @pipeline << Messages::Outgoing::Privmsg.new(target, 'eat me ' + params[:text], action)
        end
    end

end