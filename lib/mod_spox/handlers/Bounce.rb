require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Bounce < Handler
            def initialize(handlers)
                handlers[RPL_BOUNCE] = self
            end
            
            def process(string)
                if(string =~ /:Try server (\S+), port (.+)$/)
                    return Messages::Incoming::Bounce.new(string, $1, $2)
                else
                    return nil
                end
            end
        end
    end
end