module ModSpox
    module Messages
        module Incoming
            class Bounce < Message
                # server to connect to
                attr_reader :server
                # port to connect to
                attr_reader :port
                def initialize(raw, server, port)
                    super(raw)
                    @server = server
                    @port = port
                end
            end
        end
    end
end