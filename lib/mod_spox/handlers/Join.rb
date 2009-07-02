require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Join'
module ModSpox
    module Handlers
        class Join < Handler
            def initialize(handlers)
                handlers[:JOIN] = self
            end

            # :mod_spox!~mod_spox@host JOIN :#m
            
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0)
                    source = string.slice!(0..string.index(' ')-1)
                    string.slice!(0..string.index(':'))
                    channel = find_model(string.strip)
                    nick = find_model(source.slice(0..source.index('!')-1))
                    nick.source = source.dup
                    source.slice!(0..source.index('!'))
                    nick.username = source.slice!(0..source.index('@')-1)
                    source.slice!(0)
                    nick.address = source.slice!(0..source.size)
                    nick.visible = true
                    nick.save_changes
                    channel.add_nick(nick)
                    channel.save
                    return Messages::Incoming::Join.new(orig, channel, nick)
                rescue Object => boom
                    Logger.warn("Failed to parse JOIN message: #{orig}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end
        end
    end
end