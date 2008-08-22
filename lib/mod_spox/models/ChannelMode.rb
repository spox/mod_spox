module ModSpox
    module Models
        # Attribute provided by model:
        # mode:: mode that is set
        class ChannelMode < Sequel::Model(:channel_modes)
        
            set_schema do
                primary_key :id, :null => false
                varchar :mode, :null => false
                foreign_key :channel_id, :table => :channels, :unique => true, :null => false
            end
        
            # Channel this mode is associated to
            def channel
                Channel[channel_id]
            end

        end
    end
end