module ModSpox
    module Models
        class Group < Sequel::Model

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