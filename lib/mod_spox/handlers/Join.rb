require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Join < Handler
            def initialize(handlers)
                handlers[:JOIN] = self
            end

            # :mod_spox!~mod_spox@host JOIN :#m
            
            def process(string)
                orig = string.dup
                begin
                    string.slice!(0)
                    source = string.slice!(0..string.index(' ')-1)
                    string.slice!(0..string.index(':'))
                    channel = find_model(string.strip)
                    nick = find_model(source[0,source.index('!')-1])
                    nick.username = source[(source.index('!')+1)..source.index('@')-1]
                    nick.address = source[(source.index('@')+1)..source.size]
                    nick.visible = true
                    nick.save_changes
                    channel.add_nick(nick)
                    channel.save
                    return Messages::Incoming::Join.new(orig, channel, nick)
                rescue Object => boom
                    Logger.warn("Failed to parse JOIN message: #{orig}")
                    return nil
                end
            end
        end
    end
end