module ModSpox
    module Messages
        module Internal
            # This is used for incoming messages by the bot. It's
            # only real purpose is for processing messages coming
            # in from the bouncer, so the bot will perform commands.
            class Incoming
                attr_reader :message
                def initialize(m)
                    @message = m
                end
            end
        end
    end
end