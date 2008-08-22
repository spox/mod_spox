module ModSpox
    module Migrators
        class CreateNickChannels < Sequel::Migration
            def up
                Models::NickChannel.create_table unless Models::NickChannel.table_exists?
            end
            
            def down
                Models::NickChannel.drop_table if Models::NickChannel.table_exists?
            end
        end
    end
end