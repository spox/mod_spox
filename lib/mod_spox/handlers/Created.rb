require 'mod_spox/handlers/Handler'
require 'time'
module ModSpox
    module Handlers
        class Created < Handler
            def initialize(handlers)
                handlers[RPL_CREATED] = self
            end
            # :not.configured 003 spox :This server was created Tue Mar 24 2009 at 15:42:36 PDT'
            def process(string)
                begin
                    orig = string.dup
                    2.times{string.slice!(0..string.index(':'))}
                    4.times{string.slice!(0..string.index(' '))}
                    time = Time.parse(string)
                    time = nil if Time.now == time
                    return time.nil? ? nil : Messages::Incoming::Created.new(orig, time)
                rescue Object
                    return nil
                end
            end
        end
    end
end