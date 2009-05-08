require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Mode < Handler
            def initialize(handlers)
                handlers[:MODE] = self
            end

            # :spax!~spox@host MODE #m +o spax 
            def process(string)
                orig = string.dup
                begin
                    string.slice!(0)
                    source = find_model(string.slice!(0..string.index('!')-1))
                    2.times{string.slice!(0..string.index(' '))}
                    channel = find_model(string.slice!(0..string.index(' ')-1))
                    string.slice!(0)
                    modes = string.slice!(0..string.index(' ')-1)
                    string.slice!(0)
                    action = modes.slice!(0)
                    if(string.size > 0) #nick modes
                        nicks = []
                        string.split.each{|n| nicks << find_model(n)}
                        i = 0
                        modes.each_char do |m|
                            nm = Models::NickMode.find_or_create(:channel_id => channel.pk, :nick_id => nicks[i].pk)
                            action == '+' ? nm.set_mode(m) : nm.unset_mode(m)
                            i += 1
                        end
                        nicks = nicks[0] if nicks.size == 1
                        return Messages::Incoming::Mode.new(orig, "#{action}#{modes}", source, nicks, channel)
                    else #channel modes
                        modes.each_char do |m|
                            action == '+' ? channel.set_mode(m) : channel.unset_mode(c)
                        end
                        return Messages::Incoming::Mode.new(orig, "#{action}#{modes}", source, nil, channel)
                    end
                rescue Object => boom
                    Logger.warn("Failed to parse MODE message: #{orig}")
                    return nil
                end
            end
        end
    end
end