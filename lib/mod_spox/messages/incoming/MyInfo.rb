require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class MyInfo < Message
                # name of server connected to
                attr_reader :servername
                # version of server connected to
                attr_reader :version
                # user modes supported by server
                attr_reader :user_modes
                # channel modes supported by server
                attr_reader :channel_modes
                def initialize(raw, server, version, umodes, cmodes)
                    super(raw)
                    @servername = server
                    @version = version
                    @user_modes = umodes
                    @channel_modes = cmodes
                end
            end
        end
    end
end