require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/LuserOp'
module ModSpox
    module Handlers
        class LuserOp < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_LUSEROP][:value]] = self
            end
            def process(string)
                if(string =~ /(\d+) :.*?\s*[oO]perators/)
                    return Messages::Incoming::LuserOp.new(string, $1.to_i)
                else
                    Logger.warn('Failed to match RPL_LUSEROP message')
                    return nil
                end
            end
        end
    end
end