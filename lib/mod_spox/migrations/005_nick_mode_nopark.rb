module ModSpox
    module Migrations
        class NickModeNoPark < Sequel::Migration
            
            def up
                Database.db.drop_column :channels, :parked
                Database.db.add_column :nicks, :mode, :varchar, :null => true, :default => ''
                Database.db.drop_table :channel_modes
                Database.db.add_column :channels, :mode, :varchar, :null => true, :default => ''
            end
            
            def down
                Database.db.drop_column :nicks, :mode
                Database.add_column :nicks, :parked, :bool, :null => false, :default => true
            end
        end
    end
end