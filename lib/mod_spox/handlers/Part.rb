require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Part < Handler
            def initialize(handlers)
                handlers[:PART] = self
            end

            # :mod_spox!~mod_spox@host PART #m :
            # :guy2net!~guy2net@92-239-14-145.cable.ubr15.haye.blueyonder.co.uk PART #php
            
            def process(string)
                string = string.dup
                orig = string.dup
                begin
                    string.slice!(0)
                    nick = find_model(string.slice!(0..string.index('!')-1))
                    2.times{ string.slice!(0..string.index(' ')) }
                    unless(string.index(' ').nil?)
                        channel = find_model(string.slice!(0..string.index(' ')-1))
                        string.slice!(0..string.index(':'))
                    else
                        channel = find_model(string)
                        string = ''
                    end
                    channel.remove_nick(nick)
                    nick.visible = false if nick.channels.empty?
                    nick.save_changes
                    channel.save_changes
                    return Messages::Incoming::Part.new(orig, channel, nick, string)
                rescue Object => boom
                    Logger.error("Failed to parse PART message: #{orig}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end
        end
    end
end