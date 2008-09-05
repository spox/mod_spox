module ModSpox
    module Models
        class AuthGroup < Sequel::Model
            set_primary_key [:group_id, :auth_id]
            
            set_schema do
                foreign_key :group_id, :table => :groups, :null => false
                foreign_key :auth_id, :table => :auths, :null => false
                primary_key [:group_id, :auth_id]
            end            
            
            def auth
                Auth[auth_id]
            end
            
            def group
                Group[group_id]
            end
        end
    end
end