require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class BadNick < Handler
            def initialize(handlers)
                handlers[ERR_ERRONEOUSNICKNAME] = self
            end
            def process(string)
                if(string =~ /#{RPL_ERRORNEOUSNICK}\s\S+\s(\S+)\s:/)
                    return Messages::Incoming::BadNick.new(string, $1)
                else
                    Logger.warn('Failed to process RPL_ERRORONEOUSNICK message')
                    return nil
                end
            end
        end
    end
end