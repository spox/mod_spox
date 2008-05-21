module ModSpox
    module Handlers
        class YourHost < Handler
            def initialize(handlers)
                handlers[RPL_YOURHOST] = self
            end
            
            def process(string)
                if(string =~ /:Your host is (\S+), running version (.+)$/)
                    return Messages::Incoming::YourHost.new(string, $1, $2)
                else
                    Logger.log('Failed to match Your Host message')
                    return nil
                end
            end
        end
    end
end