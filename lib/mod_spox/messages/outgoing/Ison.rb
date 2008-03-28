module ModSpox
    module Messages
        module Outgoing
            class Ison
                # nick to check
                attr_reader :nick
                # nick:: nick to check
                # Check if nick is on IRC
                def initialize(nick)
                    @nick = nick
                end
            end
        end
    end
end