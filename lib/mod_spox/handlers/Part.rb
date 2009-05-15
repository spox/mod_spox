require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Part < Handler
            def initialize(handlers)
                handlers[:PART] = self
            end

            # :mod_spox!~mod_spox@host PART #m :
            
            def process(string)
                string = string.dup
                orig = string.dup
                begin
                    string.slice!(0)
                    nick = find_model(string.slice!(0..string.index('!')-1))
                    2.times{ string.slice!(0..string.index(' ')) }
                    channel = find_model(string.slice!(0..string.index(' ')-1))
                    string.slice!(0..string.index(':'))
                    channel.remove_nick(nick)
                    nick.visible = false if nick.channels.empty?
                    nick.save_changes
                    channel.save_changes
                    return Messages::Incoming::Part.new(orig, channel, nick, string)
                rescue Object
                    Logger.error("Failed to parse PART message: #{orig}")
                end
            end
        end
    end
end