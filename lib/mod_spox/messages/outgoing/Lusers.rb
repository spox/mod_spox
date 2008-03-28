module ModSpox
    module Messages
        module Outgoing
            class Lusers
                # mask for servers to match
                attr_reader :mask
                # reply from target server
                attr_reader :target
                # mask:: reply formed only by servers matching given mask
                # target:: reply formed only by target server
                # Get statistics about size of IRC network
                def initialize(mask, target='')
                    @mask = mask
                    @target = target
                end
            end
        end
    end
end