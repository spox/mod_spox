require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class LuserClient < Message
                # number of visible users
                attr_reader :users
                # number of invisible users
                attr_reader :invisible
                # number of servers
                attr_reader :servers
                # number of services
                attr_reader :services
                def initialize(raw, user, invis, servers, services)
                    super(raw)
                    @users = user
                    @invisible = invis
                    @servers = servers
                    @services = services
                end
            end
        end
    end
end