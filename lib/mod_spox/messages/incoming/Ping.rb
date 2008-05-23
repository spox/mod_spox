require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Ping < Message
                # server of origin
                attr_reader :server
                # string
                attr_reader :string
                def initialize(raw, server, string)
                    super(raw)
                    @server = server
                    @string = string
                end
            end
        end
    end
end