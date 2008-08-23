require 'mod_spox/models/Models'

module ModSpox
    module Migrations
        class InitializeModels < Sequel::Migration
            def up
                ModSpox::Models.constants.each do |const|
                    klass = ModSpox::Models.const_get(const)
                    if(klass < Sequel::Model)
                        klass.create_table unless klass.table_exists?
                    end
                end
            end
            
            def down
                ModSpox::Models.constants.each do |const|
                    klass = ModSpox::Models.get_const(const)
                    if(klass < Sequel::Model)
                        klass.drop_table if klass.table_exists?
                    end
                end
            end
        end
    end
end