require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class LuserChannels < Handler
            def initialize(handlers)
                handlers[RPL_LUSERCHANNELS] = self
            end
            def process(string)
                if(string =~ /(\d+)\s:channels/)
                    return Messages::Incoming::LuserChannels.new(string, $1.to_i)
                else
                    Logger.warn('Failed to match RPL_LUSERCHANNELS message')
                    return nil
                end
            end
        end
    end
end