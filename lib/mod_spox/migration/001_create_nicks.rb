module ModSpox
    module Migrators
        class CreateNicks < Sequel::Migration
            def up
                Models::Nick.create_table unless Models::Nick.table_exists?
            end
            
            def down
                Models::Nick.drop_table
            end
        end
    end
end