require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Kick < Handler
            def initialize(handlers)
                handlers[:KICK] = self
            end
            def process(string)
                orig = string.dup
                string.slice!(0)
                source = string.slice!(0..string.index(' ')-1)
                string.slice!(0..index(' ',3))
                channel = string.slice!(0..string.index(' ')-1)
                kickee = string.slice!(1..string.index(' ',2)-1)
                string.slice!(0..index(':'))
                kicker = find_model(source[0..index('!')-1])
                channel = find_model(channel)
                kickee = find_model(kickee)
                channel.remove_nick(kickee)
                kickee.visible = false if kickee.channels.empty?
                kickee.save_changes
                channel.save_changes
                return Messages::Incoming::Kick.new(orig, channel, kicker, kickee, string)
            end
        end
    end
end