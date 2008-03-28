module ModSpox
    module Messages
        module Internal
            class Request
                # object making request
                attr_reader :requester
                # requester:: object making request
                # Request for information
                def initialize(requester)
                    @requester = requester
                end
            end
        end
    end
end