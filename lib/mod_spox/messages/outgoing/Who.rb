module ModSpox
    module Messages
        module Outgoing
            class Who
                # mask to match
                attr_reader :mask
                # return only ops
                attr_reader :op_only
                # mask:: mask of clients to match
                # only_ops:: only return operators
                # Query for information matching given mask
                def initialize(mask, op_only=false)
                    @mask = mask
                    @op_only = op_only
                end
                
                def only_ops?
                    return op_only
                end
            end
        end
    end
end