module ModSpox
    module Handlers
        class LuserOp < Handler
            def initialize(handlers)
                handlers[RPL_LUSEROP] = self
            end
            def process(string)
                if(string =~ /(\d+) :.*?\s*[oO]perators/)
                    return Messages::Incoming::LuserOp(string, $1.to_i)
                else
                    Logger.log('Failed to match RPL_LUSEROP message')
                end
            end
        end
    end
end