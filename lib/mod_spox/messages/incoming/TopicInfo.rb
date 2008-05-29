require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class TopicInfo < Message
                # channel topic info is for
                attr_reader :channel
                # last nick to set topic
                attr_reader :nick
                # time topic was set
                attr_reader :time
                def initialize(raw, channel, nick, time)
                    super(raw)
                    @channel = channel
                    @nick = nick
                    @time = time
                end
            end
        end
    end
end