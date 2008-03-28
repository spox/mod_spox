module ModSpox
    module Messages
        module Incoming
            class Topic < Message
            
                # channel topic was set
                attr_reader :channel
                # topic messages
                attr_reader :topic
                
                def initialize(raw, channel, topic)
                    super(raw)
                    @channel = @channel
                    @topic = @topic
                end
                
            end
        end
    end
end