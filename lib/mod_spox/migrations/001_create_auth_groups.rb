module ModSpox
    module Migrators
        class CreateAuthGroups < Sequel::Migration
            def up
                Models::AuthGroup.create_table unless Models::AuthGroup.table_exists?
            end
            
            def down
                Models::AuthGroup.drop_table if Models::AuthGroup.table_exists?
            end
        end
    end
end