module ModSpox
    module Migrations
        class RemoveQuiet < Sequel::Migration
            def up
                Database.db.drop_column :channels, :quiet
            end
            def down
                Database.db.add_column :channels, :quiet, :bool
            end
        end
    end
end