require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Invite < Handler
            def initialize(handlers)
                handlers[:INVITE] = self
            end
            # :spax!~spox@host INVITE spox :#m
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0)
                    source = find_model(string.slice!(0..string.index('!')-1))
                    2.times{ string.slice!(0..string.index(' ')) }
                    target = find_model(string.slice!(0..string.index(' ')-1))
                    string.slice!(0..string.index(':'))
                    channel = find_model(string.strip)
                    return Messages::Incoming::Invite.new(orig, source, target, channel)
                rescue Object
                    Logger.error("Failed to parse INVITE message: #{orig}")
                    return nil
                end
            end
        end
    end
end