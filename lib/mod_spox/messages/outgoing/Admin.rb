module ModSpox
    module Messages
        module Outgoing
            class Admin
                # target server
                attr_reader :target
                # target:: target server
                # Request administrator info from target serve
                def initialize(target)
                    @target = target
                end
            end
        end
    end
end