module ModSpox
    module Messages
        module Outgoing
            class Squery
                # service to query
                attr_reader :service_name
                # message to send to service
                attr_reader :message
                # service_name:: name of the service to query
                # message:: message to send to service
                # Send message to a service
                def initialize(service_name, message)
                    @service_name = service_name
                    @message = message
                end
            end
        end
    end
end