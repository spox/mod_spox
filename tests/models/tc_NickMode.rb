require "#{File.dirname(__FILE__)}/../BotHolder.rb"
require 'digest/sha1'

class TestNickModeModel < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        @bot = h.bot
        @nick = ModSpox::Models::Nick.find_or_create(:nick => 'foobar')
        @channel = ModSpox::Models::Channel.find_or_create(:name => '#test')
        @mode = ModSpox::Models::NickMode.find_or_create(:nick_id => @nick.pk, :channel_id => @channel.pk)
    end
    
    def teardown
    end
    
    def test_single_mode
        @mode.set_mode('o')
        assert(@mode.set?('o'))
        @mode.unset_mode('o')
        assert(!@mode.set?('o'))
    end
    
    def test_multiple_modes
        @mode.set_mode('ov')
        assert(@mode.set?('o'))
        assert(@mode.set?('v'))
        @mode.unset_mode('ov')
        assert(!@mode.set?('o'))
        assert(!@mode.set?('v'))
        @mode.set_mode('o')
        @mode.set_mode('v')
        @mode.set_mode('v') # make sure this does nothing
        assert(@mode.set?('o'))
        assert(@mode.set?('v'))
        @mode.clear_modes
        assert(!@mode.set?('o'))
        assert(!@mode.set?('v'))
    end

end