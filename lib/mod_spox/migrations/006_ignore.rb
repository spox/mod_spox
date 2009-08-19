module ModSpox
    module Migrations
        class Ignore < Sequel::Migrations
            def up
                Database.db.create_table(:ignored_nicks) do
                    foreign_key :nick_id, :null => false, :table => :nicks, :unique => true
                    varchar :type, :null => false, :default => 'output'
                end
                Database.db.create_table(:ignored_masks) do
                    primary_key :id, :null => false
                    varchar :mask, :null => false, :unique => true
                    varchar :type, :null => false, :default => 'output'
                end
            end
            def down
                Database.db.drop_table(:ignored_nicks)
                Database.db.drop_table(:ignored_masks)
            end
        end
    end
end