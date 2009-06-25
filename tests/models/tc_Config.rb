require "#{File.dirname(__FILE__)}/../BotHolder.rb"
require 'digest/sha1'

class TestConfigModel < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        @bot = h.bot
    end
    
    def teardown
    end
    
    def test_signature
        ModSpox::Models::Config.set(:testing, 'a test')
        assert_equal('a test', ModSpox::Models::Config.val(:testing))
        assert(ModSpox::Models::Config.val(:testing) == 'a test')
    end

end