module ModSpox
    module Messages
        module Internal
            class StatusResponse < Response
                # Current status of the bot
                attr_reader :status
                # object:: Destination for response
                # status:: Status of the bot
                # Send status response to requester
                def initialize(object, status)
                    super(object)
                    @status = status
                end
            end
        end
    end
end