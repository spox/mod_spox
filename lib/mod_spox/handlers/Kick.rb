require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Kick < Handler
            def initialize(handlers)
                handlers[:KICK] = self
            end
            # :spax!~spox@host KICK #m spox :foo
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0)
                    source = string.slice!(0..string.index(' ')-1)
                    2.times{string.slice!(0..string.index(' '))}
                    channel = string.slice!(0..string.index(' ')-1)
                    string.slice!(0)
                    kickee = string.slice!(0..string.index(' ')-1)
                    string.slice!(0..string.index(':'))
                    kicker = find_model(source[0..source.index('!')-1])
                    channel = find_model(channel)
                    kickee = find_model(kickee)
                    channel.remove_nick(kickee)
                    kickee.visible = false if kickee.channels.empty?
                    kickee.save_changes
                    channel.save_changes
                    return Messages::Incoming::Kick.new(orig, channel, kicker, kickee, string)
                rescue Object => boom
                    Logger.warn("Failed to parse KICK message: #{orig}")
                    raise boom
                end
            end
        end
    end
end