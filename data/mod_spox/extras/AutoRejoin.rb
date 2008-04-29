class AutoRejoin < ModSpox::Plugin

    def initialize(pipeline)
        super
        @pipeline.hook(self, :check_kick, :Incoming_Kick)
    end
    
    def check_kick(message)
        if(message.kickee == me)
            @pipeline << Messages::Outgoing::Join.new(message.channel)
        end
    end

end