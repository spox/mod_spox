module ModSpox
    module Handlers
        class Quit < Handler
            def initialize(handlers)
                handlers[:QUIT] = self
            end
            def process(string)
                if(string =~ /^:(\S+)\sQUIT\s:(.+)$/)
                    reason = $2
                    nick = find_model($1.gsub(/!.+$/, ''))
                    nick.clear_channels
                    nick.visible = false
                    nick.save
                    return Messages::Incoming::Quit.new(string, nick, reason)
                else
                    Logger.log('Failed to parse KICK message')
                    return nil
                end
            end
        end
    end
end