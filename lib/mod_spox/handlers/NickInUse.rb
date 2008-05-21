module ModSpox
    module Handlers
        class NickInUse < Handler
            def initialize(handlers)
                handlers[:RPL_NICKNAMEINUSE] = self
            end
            def process(string)
                if(string =~ /#{RPL_NICKNAMEINUSE}\s\S+\s(\S+)\s:/)
                    return Messages::Incoming::NickInUse.new(string, $1)
                else
                    Logger.log('Failed to parse RPL_NICKNAMEINUSE message')
                    return nil
                end
            end
        end
    end
end