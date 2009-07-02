require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Ping'
module ModSpox
    module Handlers
        class Ping < Handler
            def initialize(handlers)
                handlers[:PING] = self
            end
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0) if string[0] == ':'
                    server = string[0..string.index(' ')-1]
                    message = string[string.index(':')+1..string.size]
                    server = message.dup if server == 'PING'
                    return Messages::Incoming::Ping.new(orig, server, message)
                rescue Object => boom
                    Logger.error("Failed to parse PING message: #{string}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end
        end
    end
end