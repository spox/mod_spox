require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestNickModel < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        @bot = h.bot
        @nick = ModSpox::Models::Nick.find_or_create(:nick => 'foobar')
        @channel = ModSpox::Models::Channel.find_or_create(:name => '#test')
    end

    def teardown
        @channel.remove_all_nicks
    end
    
    def test_create
        assert_kind_of(ModSpox::Models::Channel, @channel)
        assert_equal('#test', @channel.name)
    end
    
    def test_create_case
        t = ModSpox::Models::Channel.find_or_create(:name => '#TEst')
        assert_equal('#test', t.name)
    end
    
    def test_single_mode
        @channel.set_mode('s')
        assert(@channel.set?('s'))
        @channel.unset_mode('s')
        assert(!@channel.set?('s'))
    end
    
    def test_multiple_mode
        @channel.set_mode('stn')
        assert(@channel.set?('s'))
        assert(@channel.set?('t'))
        assert(@channel.set?('n'))
        @channel.clear_modes
        assert(!@channel.set?('s'))
        assert(!@channel.set?('t'))
        assert(!@channel.set?('n'))
    end
    
    def test_nick
        @channel.add_nick(@nick)
        assert(@nick.channels.include?(@channel))
        assert(@channel.nicks.include?(@nick))
        @channel.remove_nick(@nick)
        assert(!@nick.channels.include?(@channel))
        assert(!@channel.nicks.include?(@nick))
    end

end