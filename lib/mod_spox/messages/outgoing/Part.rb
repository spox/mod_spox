module ModSpox
    module Messages
        module Outgoing
            class Part
                # channel to part
                attr_reader :channel
                # reason for part
                attr_reader :reason        
                # channel:: channel to part
                # reason:: reason for part
                # Part from channel. This command only allows single parts.
                def initialize(channel, reason='')
                    @channel = channel
                    @reason = reason
                end
            end
        end
    end
end