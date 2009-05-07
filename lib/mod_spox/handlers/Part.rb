require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Part < Handler
            def initialize(handlers)
                handlers[:PART] = self
            end

            # :mod_spox!~mod_spox@host PART #m :
            
            def process(string)
                orig = string.dup
                string.slice!(0)
                nick = find_model(string.slice!(0..string.index('!')-1))
                2.times{ string.slice!(0..string.index(' ')) }
                channel = find_model(string.slice!(0..string.index(' ')-1))
                string.slice!(0..string.index(':'))
                channel.remove_nick(nick)
                channel.parked = false if nick.botnick == true
                nick.visible = false if nick.chanels.empty?
                nick.save_changes
                channel.save_changes
                return Messages::Incoming::Part.new(orig, channel, nick, string)
            end
        end
    end
end