require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class LuserChannels < Message
                # number of channels
                attr_reader :channels
                def initialize(raw, num)
                    super(raw)
                    @channels = num
                end
            end
        end
    end
end