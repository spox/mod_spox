module ModSpox
    module Messages
        module Internal
            class Response
                # object response is for
                attr_reader :origin
                # origin:: object that requested the information
                # Response of information
                def initialize(origin)
                    @origin = origin
                end
            end
        end
    end
end