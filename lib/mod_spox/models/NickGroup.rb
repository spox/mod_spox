module ModSpox
    module Models
        class NickGroup < Sequel::Model

            set_primary_key [:nick_id, :group_id]

            def nick
                Nick[nick_id]
            end

            def group
                Group[group_id]
            end
        end
    end
end