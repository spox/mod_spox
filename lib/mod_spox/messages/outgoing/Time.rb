module ModSpox
    module Messages
        module Outgoing
            class Time
                # target server
                attr_reader :target
                # target:: target server
                # Request time on server
                def initialize(channel, target='')
                    @target = target
                end
            end
        end
    end
end