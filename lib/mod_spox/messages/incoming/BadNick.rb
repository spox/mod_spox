require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class BadNick < Message
                # nick that failed (string)
                attr_reader :bad_nick
                def initialize(raw, nick)
                    super(raw)
                    @bad_nick = nick
                end
            end
        end
    end
end
                