module ModSpox
    module Models
        class Group < Sequel::Model(:groups)
        
            set_schema do
                primary_key :id, :null => false
                varchar :name, :null => false, :unique => true                
            end
            
            def name=(group_name)
                update_values :name => group_name.downcase
            end
        
            def auths
                auth = []
                AuthGroup.filter(:group_id => pk).each do |ag|
                    auth << ag.auth
                end
                return auth
            end
        end
    end
end