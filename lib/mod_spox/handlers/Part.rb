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
                    channel.nick_remove(nick)
                    mess = $3.nil? ? '' : $3
                    return Messages::Incoming::Part.new(string, channel, nick, $3.strip)
                else
                    Logger.warn('Failed to parse PART message')
                    return nil
                end
            end
        end
    end
end