module ModSpox
    module Messages
        module Internal
            class DCCListener
                attr_reader :nick
                def initialize(nick)
                    @nick = nick
                end
            end
        end
    end
end