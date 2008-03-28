module ModSpox
    module Messages
        module Outgoing
            class Users
                # target server
                attr_reader :target
                # target:: target server
                # List users on server
                def initialize(target='')
                    @target = target
                end
            end
        end
    end
end