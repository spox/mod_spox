module ModSpox
    module Messages
        module Outgoing
            # Sends message to IRC server with no modification
            class Raw
                # message to send
                attr_reader :message
                # message:: message to send
                # Creates new Raw message
                def initialize(message)
                    @message = message
                end
            end
        end
    end
end