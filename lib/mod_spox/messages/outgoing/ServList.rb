module ModSpox
    module Messages
        module Outgoing
            class ServList
                # mask
                attr_reader :mask
                # type
                attr_reader :type
                # mask:: mask
                # type:: type
                # List services currently connected to network
                def initialize(mask, type)
                    @mask = mask
                    @type = type
                end
            end
        end
    end
end