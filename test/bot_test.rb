
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'mod_spox/Bot'

class BotTest < Test::Unit::TestCase
    def test_config_default
        assert_equal('/tmp', ModSpox.config_dir)
        assert_equal('/my_dir', ModSpox.config_dir = '/my_dir')
        assert_equal('/my_dir', ModSpox.config_dir)
    end

    def test_config_set
        assert_equal('/my_dir', ModSpox.config_dir = '/my_dir')
        assert_equal('/my_dir', ModSpox.config_dir)
    end

    def test_foo
    #TODO: Write test
    flunk "TODO: Write test"
    # assert_equal("foo", bar)
    end
end
