module ModSpox
    module Migrators
        class CreateChannels < Sequel::Migration
            def up
                Models::Channel.create_table unless Models::Channel.table_exists?
            end
            
            def down
                Models::Channel.drop_table
            end
        end
    end
end