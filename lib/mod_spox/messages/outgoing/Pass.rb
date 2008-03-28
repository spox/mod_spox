module ModSpox
    module Messages
        module Outgoing
            # Send PASS command
            class Pass
                # connection password
                attr_reader :password
                # password:: connection password
                # Create new Pass
                def initialize(password)
                    @password = @message
                end
            end
        end
    end
end