require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Bounce'
module ModSpox
    module Handlers
        class Bounce < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_BOUNCE][:value]] = self
            end
            
            def process(string)
                begin
                    orig = string.dup
                    2.times{string.slice!(0..string.index(' '))}
                    server = string.slice!(0..string.index(',')-1)
                    string.slice!(0..string.index(' ',4))
                    return Messages::Incoming::Bounce.new(orig, server, string)
                rescue Object => boom
                    Logger.error("Failed to parse BOUNCE message: #{orig}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end
        end
    end
end