module ModSpox
    module Models
        # Attributes provided by model:
        # mode:: Mode that is set
        class NickMode < Sequel::Model(:nick_modes)
            
            set_schema do
                primary_key :id, :null => false
                varchar :mode, :null => false
                foreign_key :nick_id, :table => :nicks, :null => false
                foreign_key :channel_id, :table => :channels
                index [:nick_id, :channel_id], :unique => true
            end
            
            # Nick mode is associated with
            def nick
                return Nick[nick_id]
            end
            
            # Channel mode is associated with
            def channel
                return Channel[channel_id]
            end
        end
    end
end