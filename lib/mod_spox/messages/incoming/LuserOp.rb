require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class LuserOp < Message
                # number of operators visible
                attr_reader :ops
                def initialize(raw, num)
                    super(raw)
                    @ops = num
                end
            end
        end
    end
end