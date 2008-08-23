module ModSpox
    module Models
        class NickGroup < Sequel::Model
            set_schema do
                foreign_key :group_id, :table => :groups, :null => false
                foreign_key :nick_id, :table => :nicks, :null => false
                primary_key [:nick_id, :group_id]
            end
            
            def nick
                Nick[nick_id]
            end
            
            def group
                Group[group_id]
            end
        end
    end
end