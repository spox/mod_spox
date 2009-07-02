require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Mode'
module ModSpox
    module Handlers
        class Mode < Handler
            def initialize(handlers)
                handlers[:MODE] = self
            end

            # :spax!~spox@host MODE #m +o spax 
            # :spax MODE spax :+iw
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0)
                    if(string.index('!').nil?) # looks like self mode
                        source = find_model(string.slice!(0..string.index(' ')-1))
                        2.times{string.slice!(0..string.index(' '))}
                        target = find_model(string.slice!(0..string.index(' ')-1))
                        string.slice!(0..string.index(':'))
                        action = string.slice!(0)
                        action == '+' ? target.set_mode(string) : target.unset_mode(string)
                        return Messages::Incoming::Mode.new(orig, "#{action}#{string}", source, target, nil)
                    else
                        source = find_model(string.slice!(0..string.index('!')-1))
                        2.times{string.slice!(0..string.index(' '))}
                        channel = find_model(string.slice!(0..string.index(' ')-1))
                        string.slice!(0)
                        modes = string.index(' ').nil? ? string.dup : string.slice!(0..string.index(' ')-1)
                        string[0] == ' ' ? string.slice!(0) : string = ''
                        action = modes.slice!(0)
                        if(string.size > 0) #nick modes
                            nicks = []
                            string.split.each do |n|
                                ni = find_model(n)
                                ni.add_channel(channel)
                                nicks << ni
                            end
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
                    end
                rescue Object => boom
                    Logger.warn("Failed to parse MODE message: #{orig}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end
        end
    end
end