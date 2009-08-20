require 'mod_spox/messages/internal/Request'
module ModSpox
    module Messages
        module Internal
            class FilterList
                # message type
                attr_reader :type

                # type:: message type
                # Return list of currently enabled filters. If type is set,
                # only filters for that type of message will be returned
                def initialize(type)
                    @type = type
                end
            end
        end
    end
end