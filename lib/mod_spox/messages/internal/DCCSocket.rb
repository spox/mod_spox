module ModSpox
    module Messages
        module Internal
            class DCCSocket
                # ID of the contained socket
                attr_reader :socket_id
                # Models::Nick this socket is connected to
                attr_reader :nick
                # socket
                attr_reader :socket
                def initialize(id, nick, socket)
                    @socket_id = id
                    @nick = nick
                    @socket = socket
                end
            end
        end
    end
end