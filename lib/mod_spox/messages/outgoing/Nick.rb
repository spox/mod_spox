module ModSpox
    module Messages
        module Outgoing
            # Give or change nickname
            class Nick
                # nickname
                attr_reader :nick
                # nick:: nickname
                # Create a new Nick
                def initialize(nick)
                    @nick = nick
                end
            end
        end
    end
end