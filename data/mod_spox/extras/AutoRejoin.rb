class AutoRejoin < ModSpox::Plugin

    def initialize(pipeline)
        super
        @pipeline.hook(self, :check_kick, :Incoming_Kick)
        @pipeline.hook(self, :check_join, :Incoming_Join)
        @pipeline.hook(self, :check_part, :Incoming_Part)
        @pipeline.hook(self, :do_joins, :Incoming_Welcome)
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