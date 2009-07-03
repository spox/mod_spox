require 'mod_spox/messages/internal/TriggersUpdate'
require 'mod_spox/messages/outgoing/Privmsg'

class Triggers < ModSpox::Plugin

include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'triggers active', :method => :active, :group => admin, :desc => 'List all currently active triggers')
        add_sig(:sig => 'triggers list', :method => :list, :group => admin, :desc => 'List all triggers and their current status')
        add_sig(:sig => 'triggers add (\S+)', :method => :add, :group => admin, :desc => 'Add a new trigger and activate it', :params => [:trigger])
        add_sig(:sig => 'triggers remove (\d+)', :method => :remove, :group => admin, :desc => 'Remove trigger', :params => [:id])
        add_sig(:sig => 'triggers activate (\d+)', :method => :activate, :group => admin, :desc => 'Activate the trigger', :params => [:id])
        add_sig(:sig => 'triggers deactivate (\d+)', :method => :deactivate, :group => admin, :desc => 'Deactivate the trigger', :params => [:id])
    end

    def active(message, params)
        triggers = Models::Trigger.filter(:active => true)
        if(triggers)
            output = ["\2Currently active triggers:\2"]
            triggers.each do |t|
                output << "#{t.pk}: #{t.trigger}"
            end
            reply message.replyto, output
        else
            @pipeline << Privmsg.new(message.replyto, 'No triggers are currently active')
        end
    end
    
    def list(message, params)
        triggers = Models::Trigger.all
        if(triggers)
            output = ["\2Trigger listing:\2"]
            triggers.each do |t|
                output << "#{t.pk}: #{t.trigger}  ->  \2#{t.active ? "activated" : "not activated"}\2"
            end
            reply message.replyto, output
        else
            @pipeline << Privmsg.new(message.replyto, 'No triggers found')
        end
    end
    
    def add(message, params)
        Models::Trigger.find_or_create(:trigger => params[:trigger]).update(:active => true)
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
            trigger.update(:active => true)
            @pipeline << Privmsg.new(message.replyto, "Trigger #{trigger.trigger} has been activated")
            @pipeline << Messages::Internal::TriggersUpdate.new
        else
            @pipeline << Privmsg.new(message.replyto, "Failed to find trigger with ID: #{params[:id]}")
        end
    end
    
    def deactivate(message, params)
        trigger = Models::Trigger[params[:id]]
        if(trigger)
            trigger.update(:active => false)
            @pipeline << Privmsg.new(message.replyto, "Trigger #{trigger.trigger} has been deactivated")
            @pipeline << Messages::Internal::TriggersUpdate.new
        else
            @pipeline << Privmsg.new(message.replyto, "Failed to find trigger with ID: #{params[:id]}")
        end
    end

end