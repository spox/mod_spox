require "#{File.dirname(__FILE__)}/../BotHolder.rb"
require 'digest/sha1'

class TestSettingModel < Test::Unit::TestCase
    def setup
    end
    
    def teardown
    end
    
    def test_setting
        ModSpox::Models::Setting.set('Foobar', [1,2])
        s = ModSpox::Models::Setting.filter('Foobar').first
        assert(s)
        assert_equal('foobar', s.name)
        assert_kind_of(Array, s.value)
        assert_equal(2, s.value.size)
        assert_equal(s, ModSpox::Models::Setting.val(:foobar))
    end

end