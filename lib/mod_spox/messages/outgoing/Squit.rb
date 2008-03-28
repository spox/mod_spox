module ModSpox
    module Messages
        module Outgoing
            class Squit
                # server to disconnect
                attr_reader :server
                # reasone for disconnection
                attr_reader :comment
                # server:: server to disconnect
                # comment:: reason for disconnection
                # Disconnect server link. Only available if bot is oper.
                def initialize(server, comment)
                    @comment = comment
                    @server = server
                end
            end
        end
    end
end