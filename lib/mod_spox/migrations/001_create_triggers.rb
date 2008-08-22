module ModSpox
    module Migrators
        class CreateTriggers < Sequel::Migration
            def up
                Models::Trigger.create_table unless Models::Trigger.table_exists?
            end
            
            def down
                Models::Trigger.drop_table if Models::Trigger.table_exists?
            end
        end
    end
end