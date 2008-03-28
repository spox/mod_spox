module ModSpox
    module Models
        # Attribute provided by model:
        # mode:: mode that is set
        class ChannelMode < Sequel::Model(:channel_modes)
        
            # Channel this mode is associated to
            def channel
                Channel[channel_id]
            end

        end
    end
end