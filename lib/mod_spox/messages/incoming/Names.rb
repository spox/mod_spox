module ModSpox
    module Messages
        module Incoming
            class Names < Message
                # channel names are from
                attr_reader :channel
                # nicks in the channel
                attr_reader :nicks
                # ops in the channel
                attr_reader :ops
                # voiced nicks in channel
                attr_reader :voiced
                def initialize(raw, channel, nicks, ops, voiced)
                    super(raw)
                    @channel = channel
                    @nicks = nicks
                    @ops = ops
                    @voiced = voiced
                end
            end
        end
    end
end