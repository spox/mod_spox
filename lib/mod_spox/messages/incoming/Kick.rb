module ModSpox
    module Messages
        module Incoming
            class Kick < Message
                # channel user was kicked from
                attr_reader :channel
                # nick that performed the kick
                attr_reader :kicker
                # nick that was kicked
                attr_reader :kickee
                # reason for kick
                attr_reader :reason
                
                def initialize(raw, channel, kicker, kickee, reason)
                    super(raw)
                    @channel = channel
                    @kicker = kicker
                    @kickee = kickee
                    @reason = reason
                end
        
            end
        end
    end
end