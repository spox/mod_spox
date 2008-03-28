module ModSpox
    module Handlers
        class LuserUnknown < Handler
            def initialize(handlers)
                handlers[RPL_LUSERUNKNOWN] = self
            end
            def process(string)
                if(string =~ /(\d+) :.*[Uu]nknown/)
                    return Messages::Incoming::LuserUnknown(string, $1.to_i)
                else
                    Logger.log('Failed to match RPL_LUSERUNKNOWN message')
                end
            end
        end
    end
end