module ModSpox
    module Messages
        module Outgoing
            class Join
                # channel to join
                attr_reader :channel
                # key for channel
                attr_reader :key
                # channel:: channel to join
                # key:: channel key if needed
                # Join the channel. This command only allows single joins.
                def initialize(channel, key=nil)
                    @channel = channel
                    @key = key
                end
            end
        end
    end
end