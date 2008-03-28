module ModSpox
    module Messages
        module Outgoing
            class Links
                # remote server
                attr_reader :server
                # server mask
                attr_reader :mask
                # server:: remote server
                # mask:: server mask
                # List all servernames known by the server answering the query
                def initialize(server, mask)
                    @server = server
                    @mask = mask
                end
            end
        end
    end
end