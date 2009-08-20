require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class UserHost < Message
                # name of server bot is connected to
                attr_reader :servername
                # nick model for given user
                attr_reader :nick
                # username for nick
                attr_reader :username
                # host of nick
                attr_reader :host
                def initialize(raw, server, nick, username, host)
                    super(raw)
                    @servername = server
                    @nick = nick
                    @username = username
                    @host = host
                end
            end
        end
    end
end