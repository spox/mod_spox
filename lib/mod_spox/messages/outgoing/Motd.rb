module ModSpox
    module Messages
        module Outgoing
            class Motd
                # server to send request to
                attr_reader :target
                # target:: server to send request to
                # Request MOTD from target server. If no target is given
                # it requests from the current server
                def initialize(target='')
                    @target = target
                end
            end
        end
    end
end