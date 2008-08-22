module ModSpox
    module Migrators
        class CreateSignatures < Sequel::Migration
            def up
                Models::Signature.create_table unless Models::Signature.table_exists?
            end
            
            def down
                Models::Signature.drop_table if Models::Signature.table_exists?
            end
        end
    end
end