class Triggers < ModSpox::Plugin

include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        Models::Signature.find_or_create(:signature => 'triggers active', :plugin => name, :method => 'active', :group_id => admin.pk, :description => 'List all currently active triggers')
        Models::Signature.find_or_create(:signature => 'triggers list', :plugin => name, :method => 'list', :group_id => admin.pk, :description => 'List all triggers and their current status')
        Models::Signature.find_or_create(:signature => 'triggers add (\S+)', :plugin => name, :method => 'add', :group_id => admin.pk, :description => 'Add a new trigger and activate it').params = [:trigger]
        Models::Signature.find_or_create(:signature => 'triggers remove (\d+)', :plugin => name, :method => 'remove', :group_id => admin.pk, :description => 'Remove trigger').params = [:id]
        Models::Signature.find_or_create(:signature => 'triggers activate (\d+)', :plugin => name, :method => 'activate', :group_id => admin.pk, :description => 'Activate the trigger').params = [:id]
        Models::Signature.find_or_create(:signature => 'triggers deactivate (\d+)', :plugin => name, :method => 'deactivate', :group_id => admin.pk, :description => 'Deactivate the trigger').params = [:id]
    end

    def active(message, params)
        triggers = Models::Trigger.filter(:active => true)
        if(triggers)
            @pipeline << Privmsg.new(message.replyto, "\2Currently active triggers:\2")
            triggers.each do |t|
                @pipeline << Privmsg.new(message.replyto, "#{t.pk}: #{t.trigger}")
            end
        else
            @pipeline << Privmsg.new(message.replyto, 'No triggers are currently active')
        end
    end
    
    def list(message, params)
        triggers = Models::Trigger.all
        if(triggers)
            @pipeline << Privmsg.new(message.replyto, "\2Trigger listing:\2")
            triggers.each do |t|
                @pipeline << Privmsg.new(message.replyto, "#{t.pk}: #{t.trigger}  ->  \2#{t.active ? "activated" : "not activated"}\2")
            end
        else
            @pipeline << Privmsg.new(message.replyto, 'No triggers found')
        end
    end
    
    def add(message, params)
        Models::Trigger.find_or_create(:trigger => params[:trigger]).update_with_params(:active => true)
        @pipeline << Privmsg.new(message.replyto, "Trigger #{params[:trigger]} is now active")
        @pipeline << Messages::Internal::TriggersUpdate.new
    end
    
    def remove(message, params)
        trigger = Models::Trigger[params[:id]]
        if(trigger)
            trig = trigger.trigger
            trigger.destroy
            @pipeline << Privmsg.new(message.replyto, "Trigger #{trig} has been removed")
            @pipeline << Messages::Internal::TriggersUpdate.new
        else
            @pipeline << Privmsg.new(message.replyto, "Failed to find trigger with ID: #{params[:id]}")
        end
    end
    
    def activate(message, params)
        trigger = Models::Trigger[params[:id]]
        if(trigger)
            trigger.update_with_params(:active => true)
            @pipeline << Privmsg.new(message.replyto, "Trigger #{trigger.trigger} has been activated")
            @pipeline << Messages::Internal::TriggersUpdate.new
        else
            @pipeline << Privmsg.new(message.replyto, "Failed to find trigger with ID: #{params[:id]}")
        end
    end
    
    def deactivate(message, params)
        trigger = Models::Trigger[params[:id]]
        if(trigger)
            trigger.update_with_params(:active => false)
            @pipeline << Privmsg.new(message.replyto, "Trigger #{trigger.trigger} has been deactivated")
            @pipeline << Messages::Internal::TriggersUpdate.new
        else
            @pipeline << Privmsg.new(message.replyto, "Failed to find trigger with ID: #{params[:id]}")
        end
    end

end