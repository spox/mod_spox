module ModSpox
    module Messages
        module Outgoing
            class Simple
                attr_reader :message
                def initialize(message)
                    @message = message
                end
            end
        end
    end
end