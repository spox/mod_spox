require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/LuserUnknown'
module ModSpox
    module Handlers
        class LuserUnknown < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_LUSERUNKNOWN][:value]] = self
            end
            def process(string)
                if(string =~ /(\d+) :.*[Uu]nknown/)
                    return Messages::Incoming::LuserUnknown.new(string, $1.to_i)
                else
                    Logger.warn('Failed to match RPL_LUSERUNKNOWN message')
                    return nil
                end
            end
        end
    end
end