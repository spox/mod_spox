require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Join < Handler
            def initialize(handlers)
                handlers[:JOIN] = self
            end
            def process(string)
                if(string =~ /^:(\S+)\sJOIN :(\S+)$/)
                    source = $1
                    chan = $2
                    if(source =~ /^(.+?)!(.+?)@(.+)$/)
                        nick = find_model($1)
                        nick.username = $2
                        nick.address = $3
                        nick.source = source
                        nick.visible = true
                        nick.save_changes
                        channel = find_model(chan)
                        channel.add_nick(nick)
                        return Messages::Incoming::Join.new(string, channel, nick)
                    else
                        Logger.warn('Failed to parse source on JOIN message')
                        return nil
                    end
                else
                    Logger.warn('Failed to parse JOIN message')
                    return nil
                end
            end
        end
    end
end