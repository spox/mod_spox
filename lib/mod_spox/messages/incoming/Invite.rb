require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Invite < Message
                # source nick of invite
                attr_reader :source
                # target nick of invite
                attr_reader :target
                # channel invited to
                attr_reader :channel
                def initialize(raw, source, target, channel)
                    super(raw)
                    @source = source
                    @target = target
                    @channel = channel
                end
            end
        end
    end
end