module ModSpox
    module Migrations
        class PluginTables < Sequel::Migration
            def up
                unless(Database.db.table_exists?(:ban_records))
                    Database.db.create_table(:ban_records) do
                        primary_key :id
                        timestamp :stamp, :null => false
                        integer :bantime, :null => false, :default => 1
                        integer :remaining, :null => false, :default => 1
                        varchar :mask, :null => false
                        boolean :invite, :null => false, :default => false
                        boolean :removed, :null => false, :default => false
                        foreign_key :channel_id, :null => false, :table => :channels, :key => :id
                        foreign_key :nick_id, :null => false, :table => :nicks, :key => :id
                    end
                end
                unless(Database.db.table_exists?(:ban_masks))
                    Database.db.create_table(:ban_masks) do
                        primary_key :id
                        varchar :mask, :unique => true, :null => false
                        timestamp :stamp, :null => false
                        integer :bantime, :null => false, :default => 1
                        text :message
                        foreign_key :channel_id, :null => false, :table => :channels, :key => :id
                    end
                end
                unless(Database.db.table_exists?(:ban_nick_exempts))
                    Database.db.create_table(:ban_nick_exempts) do
                        primary_key :id
                        foreign_key :nick_id, :table => :nicks, :null => false, :key => :id
                        foreign_key :channel_id, :table => :channels, :key => :id
                    end
                end
                unless(Database.db.table_exists?(:ban_source_exempts))
                    Database.db.create_table(:ban_source_exempts) do
                        primary_key :id
                        varchar :source, :null => false
                        foreign_key :channel_id, :table => :channels, :key => :id
                    end
                end
                unless(Database.db.table_exists?(:ban_mode_exempts))
                    Database.db.create_table(:ban_mode_exempts) do
                        primary_key :id
                        varchar :mode, :null => false
                        foreign_key :channel_id, :table => :channels, :key => :id
                        index [:channel_id, :mode]
                    end
                end
                unless(Database.db.table_exists?(:auto_kick_records))
                    Database.db.create_table(:auto_kick_records) do
                        primary_key :id
                        text :pattern, :null => false
                        integer :bantime, :null => false, :default => 60
                        text :message, :null => false
                        foreign_key :channel_id, :table => :channels
                    end
                end
                unless(Database.db.table_exists?(:auto_kick_personals))
                    Database.db.create_table(:auto_kick_personals) do
                        primary_key :id
                        varchar :pattern, :default => nil
                        integer :bantime, :null => false, :default => 60
                        varchar :message, :null => false
                        foreign_key :nick_id, :table => :nicks
                        foreign_key :channel_id, :table => :channels
                    end
                end
                unless(Database.db.table_exists?(:mode_records))
                    Database.db.create_table(:mode_records) do
                        primary_key :id
                        boolean :voice, :null => false, :default => true
                        foreign_key :nick_id, :table => :nicks, :null => false
                        foreign_key :channel_id, :table => :channels, :null => false
                        index [:nick_id, :channel_id, :voice], :unique => true
                    end
                end
                unless(Database.db.table_exists?(:karmas))
                    Database.db.create_table(:karmas) do
                        primary_key :id
                        text :thing, :null => false
                        integer :score, :null => false, :default => 0
                        foreign_key :channel_id, :table => :channels
                        index [:thing, :channel_id], :unique => true
                    end
                end
                unless(Database.db.table_exists?(:aliases))
                    Database.db.create_table(:aliases) do
                        primary_key :id
                        foreign_key :thing_id, :null => false
                        foreign_key :aka_id, :null => false
                    end
                end
                unless(Database.db.table_exists?(:private_logs))
                    Database.db.create_table(:private_logs) do
                        primary_key :id
                        text :message, :null => false
                        text :type, :null => false, :default => 'privmsg'
                        boolean :action, :null => false, :default => false
                        timestamp :received, :null => false
                        foreign_key :sender_id, :table => :nicks
                        foreign_key :receiver_id, :table => :nicks
                    end
                end
                unless(Database.db.table_exists?(:public_logs))
                    Database.db.create_table(:public_logs) do
                        primary_key :id
                        text :message
                        text :type, :null => false, :default => 'privmsg'
                        boolean :action, :null => false, :default => false
                        timestamp :received, :null => false
                        foreign_key :sender_id, :table => :nicks
                        foreign_key :channel_id, :table => :channels
                    end
                end
                unless(Database.db.table_exists?(:quotes))
                    Database.db.create_table(:quotes) do
                        primary_key :id
                        text :quote, :null => false
                        timestamp :added, :null => false
                        foreign_key :nick_id, :table => :nicks
                        foreign_key :channel_id, :table => :channels
                    end
                end
                unless(Database.db.table_exists?(:track_infos))
                    Database.db.create_table(:track_infos) do
                        primary_key :id, :null => false
                        varchar :regex, :null => false
                        integer :score_total, :null => false, :default => 0
                        integer :score_today, :null => false, :default => 0
                        timestamp :last_score, :null => false
                        foreign_key :channel_id, :table => :channels, :null => false
                        index [:regex, :channel_id], :unique => true
                    end
                end
                unless(Database.db.table_exists?(:games))
                    Database.db.create_table(:games) do
                        primary_key :id
                        timestamp :stamp, :null => false
                        integer :shots, :null => false, :default => 6
                        integer :chamber, :null => false, :default => 1
                        foreign_key :channel_id, :null => false, :table => :channels
                    end
                end
                unless(Database.db.table_exists?(:infos))
                    Database.db.create_table(:infos) do
                        primary_key :id
                        integer :shots, :null => false, :default => 0
                        boolean :win, :null => false, :default => false
                        foreign_key :nick_id, :null => false, :table => :nicks
                        foreign_key :game_id, :null => false, :table => :games
                    end
                end
                unless(Database.db.table_exists?(:seen_logs))
                    Database.db.create_table(:seen_logs) do
                        foreign_key :nick_id, :table => :nicks, :null => false
                        foreign_key :channel_id, :table => :channels
                        varchar :type, :default => 'privmsg'
                        timestamp :received, :null => false
                        boolean :action, :null => false, :default => true
                        text :message
                        primary_key :nick_id
                    end
                end
                unless(Database.db.table_exists?(:chat_stats))
                    Database.db.create_table(:chat_stats) do
                        primary_key :id
                        integer :words, :null => false, :default => 0
                        integer :bytes, :null => false, :default => 0
                        integer :questions, :null => false, :default => 0
                        varchar :daykey, :null => false
                        foreign_key :channel_id, :table => :channels
                        foreign_key :nick_id, :table => :nicks
                    end
                end
            end
            def down
                Database.db.add_column :channels, :quiet, :bool
            end
        end
    end
end