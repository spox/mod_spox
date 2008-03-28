module ModSpox
    module Messages
        module Outgoing
            class Names
                # nick to invite
                attr_reader :nick
                # channel to invite nick to
                attr_reader :channel
                # nick:: nick to invite
                # channel:: channel to invite nick into
                # Invite user into a channel
                def initialize(nick, channel)
                    @nick = nick
                    @channel = channel
                end
            end
        end
    end
end