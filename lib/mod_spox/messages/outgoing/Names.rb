module ModSpox
    module Messages
        module Outgoing
            class Names
                # channel to request names
                attr_reader :channel
                # server to forward request to
                attr_reader :target
                # channel:: channel to request names from
                # target:: forward to this server to supply response
                # List visible nicknames. Supply empty string for channel
                # to get entire list
                def initialize(channel, target='')
                    @channel = channel
                    @target = target
                end
            end
        end
    end
end