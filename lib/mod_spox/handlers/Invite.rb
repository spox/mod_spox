require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Invite < Handler
            def initialize(handlers)
                handlers[:INVITE] = self
            end
            def process(string)
                orig = string.dup
                source = find_model(string.slice!(0..string.index('!')-1))
                2.times{ string.slice!(0..string.index(' ')) }
                target = find_model(string.slice!(0..string.index(' ')-1))
                channel = find_model(string.strip)
                return Messages::Incoming::Invite.new(orig, source, target, channel)
            end
        end
    end
end