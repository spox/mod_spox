require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Join < Message
                # channel that nick joined
                attr_reader :channel
                # nick that joined channel
                attr_reader :nick
                
                def initialize(raw, channel, nick)
                    super(raw)
                    @channel = channel
                    @nick = nick
                end
            end
        end
    end
end