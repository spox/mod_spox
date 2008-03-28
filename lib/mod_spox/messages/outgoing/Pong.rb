module ModSpox
    module Messages
        module Outgoing
            class Pong
                # server:: server to send to
                attr_reader :server
                # string:: string
                attr_reader :string
                # Send a pong
                def initialize(server, string)
                    @server = server
                    @string = string
                end
            end
        end
    end
end