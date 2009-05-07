require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Ping < Handler
            def initialize(handlers)
                handlers[:PING] = self
            end
            def process(string)
                return Messages::Incoming::Ping.new(string, string[string.index(':')..string.size], nil)
            end
        end
    end
end