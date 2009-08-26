require 'mod_spox/messages/outgoing/Join'

class AutoRejoin < ModSpox::Plugin

    def initialize(pipeline)
        super
        [:Kick, :Join,, :Part, :Welcome].each{|t| Helpers.load_message(:incoming, t)}
        @pipeline.hook(self, :check_kick, ModSpox::Messages::Incoming::Kick)
        @pipeline.hook(self, :check_join, ModSpox::Messages::Incoming::Join)
        @pipeline.hook(self, :check_part, ModSpox::Messages::Incoming::Part)
        @pipeline.hook(self, :do_joins, ModSpox::Messages::Incoming::Welcome)
    end
    
    def check_kick(message)
        if(message.kickee == me)
            @pipeline << Messages::Outgoing::Join.new(message.channel)
        end
    end
    
    def check_join(m)
        if(m.nick == me)
            m.channel.update(:autojoin => true)
        end
    end
    
    def check_part(m)
        if(m.nick == me)
            m.channel.update(:autojoin => false)
        end
    end
    
    def do_joins(m)
        Models::Channel.filter(:autojoin => true).each do |channel|
            @pipeline << Messages::Outgoing::Join.new(channel)
        end
    end

end