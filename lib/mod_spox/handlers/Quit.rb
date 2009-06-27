require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Quit < Handler
            def initialize(handlers)
                handlers[:QUIT] = self
            end

            #:spox!~spox@host QUIT :Ping timeout
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0)
                    nick = find_model(string.slice!(0..string.index('!')-1))
                    string.slice!(0..string.index(':'))
                    nick.remove_all_channels
                    nick.visible = false
                    nick.save
                    return Messages::Incoming::Quit.new(orig, nick, string)
                rescue Object => boom
                    Logger.error("Failed to parse QUIT message: #{orig}")
                    raise boom
                end
            end
        end
    end
end