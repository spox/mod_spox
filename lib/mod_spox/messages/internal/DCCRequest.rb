module ModSpox
    module Messages
        module Internal
            class DCCRequest
                attr_reader :socket_id
                def initialize(id)
                    @socket_id = id
                end
            end
        end
    end
end