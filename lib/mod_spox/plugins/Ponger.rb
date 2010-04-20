module ModSpox
    module Plugins
        # Responds to PING messages from the server
        class Ponger < ModSpox::Plugin
            def setup
                @pipeline.hook(MessageFactory::Message, self, :pong){|m|m.type == :ping}
            end

            # m:: MessageFactory::Message
            # Send returning pong
            def pong(m)
                @irc.pong(m.server, m.message)
            end
        end
    end
end