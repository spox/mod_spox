module ModSpox
    module Handlers
        class Pong < Handler
            def initialize(handlers)
                handlers[:PONG] = self
            end
            def process(string)
                if(string =~ /^:\S+\sPONG\s(\S+)\s:(.+)$/)
                    return Messages::Incoming::Pong.new(string, $1, $2)
                else
                    Logger.log('Failed to parse PONG message')
                    return nil
                end
            end
        end
    end
end