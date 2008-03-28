module ModSpox
    module Handlers
        class Ping < Handler
            def initialize(handlers)
                handlers[:PING] = self
            end
            def process(string)
                if(string =~ /^PING\s:(.+)$/)
                    return Messages::Incoming::Ping.new(string, $1, nil)
                else
                    Logger.log('Failed to match PING message')
                end
            end
        end
    end
end