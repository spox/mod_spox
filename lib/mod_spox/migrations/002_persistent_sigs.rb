module ModSpox
    module Migrations
        class PersistentSigs < Sequel::Migration

            def up
                Database.db.add_column :signatures, :enabled, :boolean, :null => false, :default => true
            end
            
            def down
                Database.db.drop_column :signatures, :enabled
            end
        end
    end
end