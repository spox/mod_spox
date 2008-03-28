module ModSpox
    module Messages
        module Incoming    
            class Quit < Message
                # nick that quit
                attr_reader :nick
                # quit message
                attr_reader :message
                def initialize(raw, nick, message)
                    super(raw)
                    @nick = nick
                    @message = message
                end
            end
        end
    end
end