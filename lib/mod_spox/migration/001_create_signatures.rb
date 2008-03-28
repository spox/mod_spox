module ModSpox
    module Migrators
        class CreateSignatures < Sequel::Migration
            def up
                Models::Signature.create_table unless Models::Signature.table_exists?
            end
            
            def down
                Models::Signature.drop_table
            end
        end
    end
end