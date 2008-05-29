require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Created < Message
                # date server was created
                attr_reader :date
                def initialize(raw, date)
                    super(raw)
                    @date = date
                end
            end
        end
    end
end