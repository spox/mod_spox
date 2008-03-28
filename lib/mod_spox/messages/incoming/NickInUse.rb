module ModSpox
    module Messages
        module Incoming
            class NickInUse < Message
                # nick that is in use (string)
                attr_reader :nick
                def initialize(raw, nick)
                    super(raw)
                    @nick = nick
                end
            end
        end
    end
end