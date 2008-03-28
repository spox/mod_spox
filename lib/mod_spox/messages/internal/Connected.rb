module ModSpox
    module Messages
        module Internal
            class Connected
                # server connected to
                attr_reader :server
                # port connected to
                attr_reader :port
                # server:: Server bot is connected to
                # port:: Port bot connected to
                # Used as notification that the bot has connected
                # to the given server
                def initialize(server, port)
                    @server = server
                    @port = port
                end
            end
        end
    end
end