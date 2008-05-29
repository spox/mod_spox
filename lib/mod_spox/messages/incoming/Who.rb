require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Who < Message
                # array of nicks
                attr_reader :nicks
                # where nicks are from (channel if who'd a channel, nick if who'd a single nick)
                attr_reader :location
                def initialize(raw, location, nicks)
                    super(raw)
                    @location = location
                    @nicks = nicks
                end
            end
        end
    end
end