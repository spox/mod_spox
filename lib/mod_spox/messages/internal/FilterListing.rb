require 'mod_spox/messages/internal/Request'
module ModSpox
    module Messages
        module Internal
            class FilterListing
                # message type
                attr_reader :type
                # filters currently enabled
                attr_reader :filters

                # type:: message type
                # filters:: array of ModSpox::Filter objects
                # Holds filter listing for given type. If type
                # is nil, all enabled filters are returned
                def initialize(type, filters)
                    @type = type
                    @filters = filters
                end
            end
        end
    end
end