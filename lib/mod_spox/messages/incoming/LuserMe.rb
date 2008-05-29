require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class LuserMe < Message
                # number of clients on server
                attr_reader :clients
                # number of servers
                attr_reader :servers
                def initialize(raw, clients, servers)
                    super(raw)
                    @clients = clients
                    @servers = servers
                end
            end
        end
    end
end