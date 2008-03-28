module ModSpox
    module Messages
        module Outgoing
            class UserMode
                # The bot's nick
                attr_reader :nick
                # mode to set/unset
                attr_reader :mode
                # nick:: The bot's nick
                # mode:: mode to set/unset
                # Create UserMode message
                def initialize(nick, mode)
                    @nick = nick
                    @mode = mode
                end
            end
        end
    end
end