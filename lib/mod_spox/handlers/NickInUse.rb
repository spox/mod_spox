require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class NickInUse < Handler
            def initialize(handlers)
                handlers[ERR_NICKNAMEINUSE] = self
            end
            def process(string)
                if(string =~ /#{ERR_NICKNAMEINUSE}\s\S+\s(\S+)\s:/)
                    return Messages::Incoming::NickInUse.new(string, $1)
                else
                    Logger.warn('Failed to parse ERR_NICKNAMEINUSE message')
                    return nil
                end
            end
        end
    end
end