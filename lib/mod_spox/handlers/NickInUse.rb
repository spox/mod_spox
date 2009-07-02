require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/NickInUse'
module ModSpox
    module Handlers
        class NickInUse < Handler
            def initialize(handlers)
                handlers[RFC[:ERR_NICKNAMEINUSE][:value]] = self
            end
            def process(string)
                if(string =~ /#{RFC[:ERR_NICKNAMEINUSE][:value]}\s\S+\s(\S+)\s:/)
                    return Messages::Incoming::NickInUse.new(string, $1)
                else
                    Logger.warn('Failed to parse ERR_NICKNAMEINUSE message')
                    return nil
                end
            end
        end
    end
end