module ModSpox
    module Messages
        module Outgoing
            class Trace
                # target to trace to
                attr_reader :target
                # target:: target to trace to
                # Find route to specifc server
                def initialize(target)
                    @target = target
                end
            end
        end
    end
end