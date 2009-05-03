module ModSpox
    module Migrations
        class AuthRestructureModeFix < Sequel::Migration

            def up
                Database.db.drop_column :auths, :mask
                Database.db.create_table(:auth_masks) do
                    primary_key :id, :null => false
                    varchar :mask, :null => false, :unique => true
                end
                Database.db.create_table(:auth_masks_groups) do
                    foreign_key :auth_mask_id, :table => :auth_masks, :null => false
                    foreign_key :group_id, :null => false
                    primary_key [:auth_mask_id, :group_id]
                end
                Database.db.create_table(:auth_masks_nicks) do
                    foreign_key :auth_mask_id, :table => :auth_masks, :null => false
                    foreign_key :nick_id, :null => false
                    primary_key [:nick_id, :auth_mask_id]
                end
                Database.db.drop_table :nick_groups
            end

            def down
                Database.db.drop_table(:auth_masks_group)
                Database.db.drop_table(:auth_masks_nicks)
                Database.db.drop_table(:auth_masks)
            end
        end
    end
end