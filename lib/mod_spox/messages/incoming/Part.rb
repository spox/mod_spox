module ModSpox
    module Messages
        module Incoming
            class Part < Message
                # channel user parted from
                attr_reader :channel
                # nick that parted from channel
                attr_reader :nick
                # reason for parting
                attr_reader :reason
                def initialize(raw, channel, nick, reason)
                    super(raw)
                    @channel = channel
                    @nick = nick
                    @reason = reason
                end
            end
        end
    end
end