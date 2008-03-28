module ModSpox
    module Messages
        module Outgoing
            class ChannelMode
                # channel to set mode
                attr_reader :channel
                # mode to set/unset
                attr_reader :mode
                # target of mode change
                attr_reader :target
                # channel:: channel to set mode in
                # mode:: mode to set/unset
                # target:: target of mode change
                # Query/change channel modes. Target can also be used as mode
                # options for cases like: MODE #chan +l 10 where the target
                # would hold the limit value.
                def initialize(channel, mode, target='')
                    @channel = channel
                    @mode = mode
                    @target = target
                end
            end
        end
    end
end