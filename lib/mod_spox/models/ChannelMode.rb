require 'mod_spox/models/Channel'

module ModSpox
    module Models

        class ChannelMode < Sequel::Model
            many_to_one :channel, :class => 'Models::Channel'

            # m:: single character mode
            # returns if mode is currently set for
            # channel
            def set?(m)
                return !mode.index(m).nil?
            end

            # m:: single character mode
            # set a mode for the channel
            # TODO: add some type checks
            def set(m)
                mode = mode + m
            end

            # m:: single character mode
            # unset a mode for the channel
            def unset(m)
                mode = mode.gsub(m, '')
            end
        end
    end
end