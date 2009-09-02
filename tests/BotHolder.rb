['sequel', 'thread', 'etc', 'getoptlong', 'logger'].each{|f|require f}
# lets get sequel setup like we want it #
require 'sequel/extensions/migration'
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :schema
Sequel::Model.unrestrict_primary_key
require 'mod_spox/Version'
require 'mod_spox/Loader'
require 'test/unit'
require 'singleton'

class BotHolder
    include Singleton
    attr_reader :bot
    def initialize
        ModSpox::Database.db = nil
        begin
            File.unlink('test.db') if File.exists?('test.db')
            ModSpox.initialize_bot(Sequel.sqlite('test.db'))
        rescue SQLite3::BusyException
            ModSpox::Database.reconnect
            retry
        end
        require 'mod_spox/Bot'
        @bot = ModSpox::Bot.new
        m = ModSpox::Models::Nick.find_or_create(:nick => 'mod_spox')
        m.update(:botnick => true)
    end

end