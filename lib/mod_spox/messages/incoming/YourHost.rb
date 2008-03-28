module ModSpox
    module Messages
        module Incoming
            class YourHost < Message
                # name of server bot is connected to
                attr_reader :servername
                # version of server bot is connected to
                attr_reader :version
                def initialize(raw, server, version)
                    super(raw)
                    @servername = server
                    @version = version
                end
            end
        end
    end
end