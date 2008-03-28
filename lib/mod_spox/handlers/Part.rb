module ModSpox
    module Handlers
        class Part < Handler
            def initialize(handlers)
                handlers[:PART] = self
            end
            def process(string)
                if(string =~ /^:(\S+) PART (\S+) :(.*)$/)
                    channel = find_model($2)
                    nick = find_model($1.gsub(/!.+$/, ''))
                    channel.nick_remove(nick)
                    return Messages::Incoming::Part.new(string, channel, nick, $3)
                else
                    Logger.log('Failed to parse PART message')
                end
            end
        end
    end
end