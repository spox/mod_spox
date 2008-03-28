module ModSpox
    module Messages
        module Outgoing
            class UserHost
                # nick to query
                attr_reader :nick
                # nick:: nick to query
                # Request host of nick
                def initialize(nick)
                    @nick = nick
                end
            end
        end
    end
end