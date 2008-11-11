module ModSpox
    module Migrations
        class InitializeModels < Sequel::Migration

            def up
                Database.db.alter_table :nick_modes do
                    drop_index(:nick_id, :channel_id)
                    add_index(:nick_id, :channel_id)
                end
            end
        end
    end
end