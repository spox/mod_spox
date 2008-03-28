module ModSpox
    module Messages
        module Incoming
            class Welcome < Message
                # server bot is connected to
                attr_reader :server
                # welcome message from server
                attr_reader :message
                # nick of the bot
                attr_reader :nick
                # username of the bot
                attr_reader :username
                # hostname of the bot
                attr_reader :hostname
                def initialize(raw, server, message, nick, username, hostname)
                    super(raw)
                    @server = server
                    @message = message
                    @nick = nick
                    @username = username
                    @hostname = hostname
                end
            end
        end
    end
end