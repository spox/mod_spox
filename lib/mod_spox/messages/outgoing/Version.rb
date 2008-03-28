module ModSpox
    module Messages
        module Outgoing
            class Version
                # target server to query
                attr_reader :target
                # target:: target server to query
                # Query version of server. Connected server is queried
                # if target is not defined
                def initialize(target='')
                    @target = target
                end
            end
        end
    end
end