module ModSpox
    module Messages
        module Outgoing
            class List
                # channel to list
                attr_reader :channel
                # server to forward request to
                attr_reader :target
                # channel:: channel to list
                # target:: forward to this server to supply response
                # List channels and their topics
                def initialize(channel, target='')
                    @channel = channel
                    @target = target
                end
            end
        end
    end
end