require 'mod_spox/messages/internal/Request'
module ModSpox
    module Messages
        module Internal
            class FilterAdd
                # ModSpox::Filter
                attr_reader :filter
                # Type of messages to filter
                attr_reader :type
                # filter:: ModSpox::Filter type object
                # type:: message type to filter
                # Add a new filter to the pipeline
                def initialize(filter, type)
                    @filter = filter
                    @type = type
                end
            end
        end
    end
end