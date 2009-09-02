require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestBotConfig < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @testdir = '/home/testing'
        ModSpox.mod_spox_path = @testdir
        ModSpox::BotConfig.populate(false) # don't try and create directory
    end

    def test_valid
        gemname, gem = Gem.source_index.find{|name, spec| spec.name == 'mod_spox' && spec.version.version = ModSpox.botversion}
        path = gem.full_gem_path
        assert_equal(path, ModSpox::BotConfig[:basepath])
        assert_equal("#{path}/lib/mod_spox", ModSpox::BotConfig[:libpath])
        assert_equal("#{path}/data/mod_spox", ModSpox::BotConfig[:datapath])
        assert_equal("#{path}/data/mod_spox/plugins", ModSpox::BotConfig[:pluginpath])
        assert_equal("#{path}/data/mod_spox/extras", ModSpox::BotConfig[:pluginextraspath])
        assert_equal("#{@testdir}/.mod_spox", ModSpox::BotConfig[:userpath])
        assert_equal("#{@testdir}/.mod_spox/plugins", ModSpox::BotConfig[:userpluginpath])
        assert_equal("#{@testdir}/.mod_spox/config", ModSpox::BotConfig[:userconfigpath])
    end

    def test_invalid
        assert_raise(ModSpox::Exceptions::UnknownKey){ ModSpox::BotConfig[:fubar] }
        assert_raise(ModSpox::Exceptions::UnknownKey){ ModSpox::BotConfig[0] }
        assert_raise(ModSpox::Exceptions::UnknownKey){ ModSpox::BotConfig['fail'] }
        # assert_raise(ArgumentError){ ModSpox::BotConfig[nil] } i don't even know how to remove the to_s method
    end

    def test_configured
        assert(!ModSpox::BotConfig.configured?)
    end
end