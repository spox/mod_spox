require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Created'
require 'time'
module ModSpox
    module Handlers
        class Created < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_CREATED][:value]] = self
            end
            # :not.configured 003 spox :This server was created Tue Mar 24 2009 at 15:42:36 PDT'
            def process(string)
                string = string.dup
                begin
                    orig = string.dup
                    2.times{string.slice!(0..string.index(':'))}
                    4.times{string.slice!(0..string.index(' '))}
                    time = Time.parse(string)
                    time = nil if Time.now == time
                    return time.nil? ? nil : Messages::Incoming::Created.new(orig, time)
                rescue Object => boom
                    Logger.error("Failed to parse RPL_CREATED message: #{orig}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end
        end
    end
end