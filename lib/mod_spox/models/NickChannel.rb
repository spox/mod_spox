module ModSpox
    module Models
        # This model is for internal use only to provide a
        # proper relation between Nick and Channel
        class NickChannel < Sequel::Model
        
            include Models
            
            set_schema do
                foreign_key :nick_id, :table => :nicks, :null => false
                foreign_key :channel_id, :table => :channels, :null => false
                primary_key [:nick_id, :channel_id]
            end
            
            after_save do
                c = Channel[channel_id]
                n = Nick[nick_id]
                n.visible = true
                n.save
                c.parked = true
                c.save
            end
            
            after_destroy do
                c = Channel[channel_id]
                n = Nick[nick_id]
                if(n.channels.size < 1)
                    n.visible = false
                    n.save
                    NickMode.filter(:nick_id => nick_id).each{|n|n.destroy}
                end
                if(c.nicks.size < 1)
                    c.parked = false
                    c.save
                    NickMode.filter(:channel_id => channel_id).each{|n|n.destroy}
                    ChannelMode.filter(:channel_id => channel_id).each{|n|n.destroy}
                end
            end
            
            def nick
                Nick[nick_id]
            end
            
            def channel
                Channel[channel_id]
            end
        end
    end
end