require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Motd < Message
                # Message of the day
                attr_reader :motd
                # Server message is from
                attr_reader :server
                def initialize(raw, motd, server)
                    super(raw)
                    @motd = motd
                    @server = server
                end
            end
        end
    end
end