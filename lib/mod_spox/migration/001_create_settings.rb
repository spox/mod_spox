module ModSpox
    module Migrators
        class CreateSettings < Sequel::Migration
            def up
                Models::Setting.create_table unless Models::Setting.table_exists?
            end
            
            def down
                Models::Setting.drop_table
            end
        end
    end
end