module ModSpox
    module Migrators
        class CreateGroups < Sequel::Migration
            def up
                Models::Group.create_table unless Models::Group.table_exists?
            end
            
            def down
                Models::Group.drop_table if Models::Group.table_exists?
            end
        end
    end
end