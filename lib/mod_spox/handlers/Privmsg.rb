require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Privmsg < Handler
            def initialize(handlers)
                handlers[:PRIVMSG] = self
            end

            # :spox!~spox@host PRIVMSG #m :foobar
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0)
                    base_source = string.slice!(0..string.index(' ')-1)
                    orig_source = base_source.dup
                    string.slice!(0..string.index(' ',3))
                    target = find_model(string.slice!(0..string.index(' ')-1))
                    string.slice!(0..string.index(':'))
                    string.strip!
                    source = find_model(base_source.slice!(0..base_source.index('!')-1))
                    base_source.slice!(0)
                    source.username = base_source.slice!(0..base_source.index('@')-1)
                    base_source.slice!(0)
                    source.address = base_source.strip
                    source.source = orig_source
                    source.save_changes
                    source.add_channel(target) if target.is_a?(Models::Channel)
                    return Messages::Incoming::Privmsg.new(orig, source, target, string)
                rescue Object
                    Logger.warn("Failed to parse PRIVMSG message: #{orig}")
                    return nil
                end
            end
        end
    end
end