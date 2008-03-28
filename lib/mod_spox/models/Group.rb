module ModSpox
    module Models
        class Group < Sequel::Model(:groups)
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