require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/YourHost'
module ModSpox
    module Handlers
        class YourHost < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_YOURHOST][:value]] = self
            end
            
            def process(string)
                if(string =~ /:Your host is (\S+), running version (.+)$/)
                    return Messages::Incoming::YourHost.new(string, $1, $2)
                else
                    Logger.warn('Failed to match Your Host message')
                    return nil
                end
            end
        end
    end
end