require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/BadNick'
module ModSpox
    module Handlers
        class BadNick < Handler
            def initialize(handlers)
                handlers[RFC[:ERR_ERRONEOUSNICKNAME][:value]] = self
            end
            def process(string)
                if(string =~ /#{RFC[:ERR_ERRONEOUSNICKNAME][:value]}\s\S+\s(\S+)\s:/)
                    return Messages::Incoming::BadNick.new(string, $1)
                else
                    Logger.warn('Failed to process RPL_ERRORONEOUSNICK message')
                    return nil
                end
            end
        end
    end
end