require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Bounce < Handler
            def initialize(handlers)
                handlers[RPL_BOUNCE] = self
            end
            
            def process(string)
                orig = string.dup
                2.times{string.slice!(0..string.index(' '))}
                server = string.slice!(0..string.index(',')-1)
                string.slice!(0..string.index(' ',4))
                return Messages::Incoming::Bounce.new(orig, server, string)
            end
        end
    end
end