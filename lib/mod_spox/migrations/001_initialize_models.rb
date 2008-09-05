require 'mod_spox/models/Models'

module ModSpox
    module Migrations
        class InitializeModels < Sequel::Migration
            @@models = [:Nick, :Channel, :Auth, :Group,
                        :Config, :Server, :Setting, :Signature,
                        :Trigger, :AuthGroup, :ChannelMode,
                        :NickChannel, :NickGroup, :NickMode]
            def up
                @@models.each do |const|
                    klass = ModSpox::Models.const_get(const)
                    if(klass < Sequel::Model)
                        klass.create_table unless klass.table_exists?
                    end
                end
            end

            def down
                @@models.reverse.each do |const|
                    klass = ModSpox::Models.get_const(const)
                    if(klass < Sequel::Model)
                        klass.drop_table if klass.table_exists?
                    end
                end
            end
        end
    end
end