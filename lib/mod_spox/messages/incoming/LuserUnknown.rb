require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class LuserUnknown < Message
                # number of unknown users
                attr_reader :unknown
                def initialize(raw, num)
                    super(raw)
                    @unknown = num
                end
            end
        end
    end
end