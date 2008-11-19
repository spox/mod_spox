module ModSpox
    module Migrations
        class InitializeModels < Sequel::Migration

            def up
                Database.db << "SET FOREIGN_KEY_CHECKS = 0" if Database.type == :mysql
                Database.db.create_table(:nicks) do
                    primary_key :id, :null => false
                    varchar :nick, :null => false, :unique => true
                    varchar :username
                    varchar :real_name
                    varchar :address
                    varchar :host
                    varchar :source
                    timestamp :connected_at
                    varchar :connected_to
                    integer :seconds_idle
                    boolean :visible, :null => false, :default => false
                    boolean :away, :null => false, :default => false
                    boolean :botnick, :null => false, :default => false
                end unless Database.db.table_exists?(:nicks)
                Database.db.create_table(:channels) do
                    primary_key :id, :null => false
                    varchar :name, :null => false, :unique => true
                    varchar :password
                    boolean :autojoin, :null => false, :default => false
                    varchar :topic
                    boolean :quiet, :null => false, :default => false
                    boolean :parked, :null => false, :default => false
                end unless Database.db.table_exists?(:channels)
                Database.db.create_table(:auths) do
                    primary_key :id, :null => false
                    varchar :password
                    boolean :services, :null => false, :default => false
                    varchar :mask, :unique => true, :default => nil
                    boolean :authed, :null => false, :default => false
                    foreign_key :nick_id, :table => :nicks, :unique => true, :null => false, :key => :id
                end unless Database.db.table_exists?(:auths)
                Database.db.create_table(:groups) do
                    primary_key :id, :null => false
                    varchar :name, :null => false, :unique => true
                end unless Database.db.table_exists?(:groups)
                Database.db.create_table(:configs) do
                    primary_key :id, :null => false
                    varchar :name, :null => false, :unique => true
                    varchar :value
                end unless Database.db.table_exists?(:configs)
                Database.db.create_table(:servers) do
                    primary_key :id, :null => false
                    varchar :host, :null => false
                    integer :port, :null => false, :default => 6667
                    integer :priority, :null => false, :default => 0
                    boolean :connected, :null => false, :default => false
                    index [:host, :port], :unique => true
                end unless Database.db.table_exists?(:servers)
                Database.db.create_table(:settings) do
                    primary_key :id, :null => false
                    varchar :name, :null => false, :unique => true
                    text :value
                end unless Database.db.table_exists?(:settings)
                Database.db.create_table(:signatures) do
                    primary_key :id, :null => false
                    varchar :signature, :null => false
                    varchar :params
                    foreign_key :group_id, :table => :groups, :default => nil, :key => :id
                    varchar :method, :null => false
                    varchar :plugin, :null => false
                    varchar :description
                    varchar :requirement, :null => false, :default => 'both'
                end unless Database.db.table_exists?(:signatures)
                Database.db.create_table(:triggers) do
                    primary_key :id, :null => false
                    varchar :trigger, :unique => true, :null => false
                    boolean :active, :null => false, :default => false
                end unless Database.db.table_exists?(:triggers)
                Database.db.create_table(:auth_groups) do
                    foreign_key :group_id, :table => :groups, :null => false, :key => :id
                    foreign_key :auth_id, :table => :auths, :null => false, :key => :id
                    primary_key [:group_id, :auth_id]
                end unless Database.db.table_exists?(:auth_groups)
                Database.db.create_table(:channel_modes) do
                    primary_key :id, :null => false
                    varchar :mode, :null => false
                    foreign_key :channel_id, :table => :channels, :unique => true, :null => false, :key => :id
                end unless Database.db.table_exists?(:channel_modes)
                Database.db.create_table(:nick_channels) do
                    foreign_key :nick_id, :table => :nicks, :null => false, :key => :id
                    foreign_key :channel_id, :table => :channels, :null => false, :key => :id
                    primary_key [:nick_id, :channel_id]
                end unless Database.db.table_exists?(:nick_channels)
                Database.db.create_table(:nick_groups) do
                    foreign_key :group_id, :table => :groups, :null => false, :key => :id
                    foreign_key :nick_id, :table => :nicks, :null => false, :key => :id
                    primary_key [:nick_id, :group_id]
                end unless Database.db.table_exists?(:nick_groups)
                Database.db.create_table(:nick_modes) do
                    primary_key :id, :null => false
                    varchar :mode, :null => false
                    foreign_key :nick_id, :table => :nicks, :null => false, :key => :id
                    foreign_key :channel_id, :table => :channels, :key => :id
                    index [:nick_id, :channel_id]
                end unless Database.db.table_exists?(:nick_modes)
                Database.db << "SET FOREIGN_KEY_CHECKS = 1" if Database.type == :mysql
            end

            def down
                [:nick_modes, :nick_groups, :nick_channels, :channel_modes, :auth_groups,
                 :triggers, :signatures, :settings, :servers, :configs, :groups, :auths,
                 :channels, :nicks].each do |table|
                    Database.db.drop_table(table) if Database.db.table_exists?(table)
                end
            end
        end
    end
end