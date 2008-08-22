module ModSpox
    module Migrators
        class CreateAuths < Sequel::Migration
            def up
                Models::Auth.create_table unless Models::Auth.table_exists?
            end
            
            def down
                Models::Auth.drop_table if Models::Auth.table_exists?
            end
        end
    end
end