module ModSpox
    module Messages
        module Outgoing
            class Topic
                # channel to set topic
                attr_reader :channel
                # the topic
                attr_reader :topic
                # channel:: channel to set topic in
                # topic:: the topic
                # Set the topic for the channel
                def initialize(channel, topic)
                    @channel = channel
                    @topic = topic
                end
            end
        end
    end
end