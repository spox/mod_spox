module ModSpox
    module Messages
        module Outgoing
            class Kick
                # nick of user to kick
                attr_reader :nick
                # channel to kick user out of
                attr_reader :channel
                # reason for kick
                attr_reader :reason
                # nick:: nick of user to kick
                # channel:: channel to kick user out of
                # reason:: reason for kick
                # Request the forced removal of a user from a channel 
                def initialize(nick, channel, reason=nil)
                    @nick = nick
                    @channel = channel
                    @reason = reason
                end
            end
        end
    end
end