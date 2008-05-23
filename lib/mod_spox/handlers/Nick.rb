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
                    if(old_nick.botnick == true)
                        old_nick.botnick = false
                        old_nick.save
                        new_nick.botnick = true
                        new_nick.save
                    end
                    return Messages::Incoming::Nick.new(string, old_nick, new_nick)
                else
                    Logger.log('Failed to parse NICK message')
                    return nil
                end
            end
        end
    end
end