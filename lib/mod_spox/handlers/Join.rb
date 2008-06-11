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
                        do_save = false
                        nick = find_model($1)
                        unless(nick.username == $2)
                            nick.username == $2
                            do_save = true
                        end
                        unless(nick.address == $3)
                            nick.address = $3
                            do_save = true
                        end
                        unless(nick.source == source)
                            nick.source = source
                            do_save = true
                        end
                        unless(nick.visible == true)
                            nick.visible = true
                            do_save = true
                        end
                        nick.save if do_save
                        channel = find_model(chan)
                        channel.nick_add(nick)
                        return Messages::Incoming::Join.new(string, channel, nick)
                    else
                        Logger.log('Failed to parse source on JOIN message')
                        return nil
                    end
                else
                    Logger.log('Failed to parse JOIN message')
                    return nil
                end
            end
        end
    end
end