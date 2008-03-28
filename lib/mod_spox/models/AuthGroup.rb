module ModSpox
    module Models
        class AuthGroup < Sequel::Model(:auth_groups)
            set_primary_key [:group_id, :auth_id]
            
            def auth
                Auth[auth_id]
            end
            
            def group
                Group[group_id]
            end
        end
    end
end