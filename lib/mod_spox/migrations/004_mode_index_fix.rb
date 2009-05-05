module ModSpox
    module Migrations
        class ModeIndexFix < Sequel::Migration
            
            def up
                Database.db.drop_index :nick_modes, [:nick_id, :channel_id]
                Database.db.add_index :nick_modes, [:nick_id, :channel_id], :unique => true
                Database.db.drop_column :nick_modes, :mode
                Database.db.add_column :nick_modes, :mode, :varchar, :null => true, :default => ''
            end
            
            def down
                Database.db.drop_index :nick_modes, [:nick_id, :channel_id]
                Database.db.add_index :nick_modes, [:nick_id, :channel_id]
            end
        end
    end
end