require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Part < Handler
            def initialize(handlers)
                handlers[:PART] = self
            end
            def process(string)
                if(string =~ /^:(\S+) PART (\S+)( .+)?$/)
                    channel = find_model($2)
                    nick = find_model($1.gsub(/!.+$/, ''))
                    channel.remove_nick(nick)
                    channel.parked = false if nick.botnick == true
                    nick.visible = false if nick.channels.empty?
                    nick.save_changes
                    channel.save_changes
                    mess = $3.nil? ? '' : $3
                    return Messages::Incoming::Part.new(string, channel, nick, mess)
                else
                    Logger.warn('Failed to parse PART message')
                    return nil
                end
            end
        end
    end
end