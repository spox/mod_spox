module ModSpox
    module Migrators
        class CreateServers < Sequel::Migration
            def up
                Models::Server.create_table unless Models::Server.table_exists?
            end
            
            def down
                Models::Server.drop_table if Models::Server.table_exists?
            end
        end
    end
end