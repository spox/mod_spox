require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Mode < Handler
            def initialize(handlers)
                handlers[:MODE] = self
            end
            
            def process(string)
                orig = string.dup
                string.slice!(0)
                source = find_model(string.slice!(0..string.index('!')-1))
                string.slice!(0..string.index('MODE '))
                channel = find_model(string.slice!(0..string.index(' ')-1))
                string.slice!(0)
                modes = string.slice!(0..index(' ')-1)
                string.slice!(0)
                action = modes.slice!(0)
                if(string.size > 0) #nick modes
                    nicks = []
                    string.split.each{|n| nicks << find_model(n)}
                    modes.each_char do |m|
                        nm = Models::NickMode.find_or_create(:channel_id => channel.pk, :nick_id => nick.pk)
                        action == '+' ? nm.set_mode(m) : nm.unset_mode(m)
                    end
                    nicks = nicks[0] if nicks.size == 1
                    return Messages::Incoming::Mode.new(orig, "#{action}#{modes}", source, nicks, channel)
                else #channel modes
                    modes.each_char do |m|
                        action == '+' ? channel.set_mode(m) : channel.unset_mode(c)
                    end
                    return Messages::Incoming::Mode.new(orig, "#{action}#{modes}", source, nil, channel)
                end
            end
        end
    end
end