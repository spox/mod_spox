module ModSpox
    module Messages
        module Outgoing
            class Summon
                # nick to summon
                attr_reader :nick
                # server nick is on
                attr_reader :target
                # channel to summon to
                attr_reader :channel
                # nick:: nick to summon
                # target:: server which nick is on
                # channel:: channel to summon to
                # Summon a user
                def initialize(nick, target='', channel='')
                    @nick = nick
                    @channel = channel
                    @target = target
                end
            end
        end
    end
end