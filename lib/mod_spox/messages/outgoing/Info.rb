module ModSpox
    module Messages
        module Outgoing
            class Info
                # target server
                attr_reader :target
                # target:: target server
                # Request information about target server
                def initialize(target='')
                    @target = target
                end
            end
        end
    end
end