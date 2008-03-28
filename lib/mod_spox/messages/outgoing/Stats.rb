module ModSpox
    module Messages
        module Outgoing
            class Stats
                # the query
                attr_reader :query
                # target server
                attr_reader :target
                # query:: single character for query
                # target:: target server to query (or connected server if unset)
                def initialize(query, target='')
                    @query = query
                    @target = target
                end
            end
        end
    end
end