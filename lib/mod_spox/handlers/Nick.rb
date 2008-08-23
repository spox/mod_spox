require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Nick < Handler
            def initialize(handlers)
                handlers[:NICK] = self
            end
            def process(string)
                if(string =~ /^:([^!]+)!\S+\sNICK\s:(.+)$/)
                    old_nick = find_model($1)
                    new_nick = find_model($2)
                    old_nick.visible = false
                    new_nick.visible = true
                    old_nick.channels.each do |channel|
                        new_nick.channel_add(channel)
                    end
                    old_nick.clear_channels
                    if(old_nick.botnick == true)
                        old_nick.botnick = false
                        new_nick.botnick = true
                    end
                    new_nick.save
                    old_nick.save
                    return Messages::Incoming::Nick.new(string, old_nick, new_nick)
                else
                    Logger.log('Failed to parse NICK message')
                    return nil
                end
            end
        end
    end
end