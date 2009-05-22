require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestNickModel < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        @bot = h.bot
        @nick = ModSpox::Models::Nick.find_or_create(:nick => 'foobar')
        @group = ModSpox::Models::Group.find_or_create(:name => 'test')
        @channel = ModSpox::Models::Channel.find_or_create(:name => '#test')
    end

    def teardown
        @nick.auth.authed = false
        @nick.auth.remove_all_groups
        @nick.clear_channels
    end
    
    def test_nick
        assert_equal('foobar', @nick.nick)
    end
    
    def test_nick_case
        nick = ModSpox::Models::Nick.find_or_create(:nick => 'FooBaR')
        nick.refresh
        assert_equal('foobar', nick.nick)
    end
    
    def test_address
        @nick.address = 'some.domain'
        assert_equal('some.domain', @nick.address)
        assert_equal('some.domain', @nick.host)
    end
    
    def test_visible
        @nick.visible = true
        @nick.address = 'some.domain'
        @nick.real_name = 'foo bar'
        @nick.username = '~spox'
        @nick.source = 'spox!~spox@some.domain'
        @nick.connected_at = Time.now
        @nick.connected_to = 'irc.domain'
        @nick.seconds_idle = 10
        @nick.away = true
        @nick.save_changes
        @nick.refresh
        @nick.visible = false
        @nick.refresh
        assert_nil(@nick.address)
        assert_nil(@nick.real_name)
        assert_nil(@nick.username)
        assert_nil(@nick.source)
        assert_nil(@nick.connected_at)
        assert_nil(@nick.connected_to)
        assert_nil(@nick.seconds_idle)
        assert(!@nick.away)
    end
    
    def test_auth
        assert_kind_of(ModSpox::Models::Auth, @nick.auth)
    end
    
    def test_auth_groups
        assert_kind_of(Array, @nick.auth_groups)
        assert(@nick.auth_groups.empty?)
    end
    
    def test_add_group
        @nick.auth.add_group(@group)
        @nick.auth.authed = true
        assert(@nick.auth_groups.include?(@group))
    end

    def test_in_group
        @nick.auth.add_group(@group)
        @nick.auth.authed = true
        assert(@nick.in_group?(@group))
    end

    def test_not_in_group
        assert(!@nick.in_group?(@group))
    end

    def test_clear_channels
        @nick.visible = true
        @nick.refresh
        @nick.add_channel(@channel)
        assert_equal(1, @nick.channels.size)
        @nick.clear_channels
        assert(!@nick.visible)
        assert_equal(0, @nick.channels.size)
    end

    def test_channel_op
        @nick.visible = true
        @nick.add_channel(@channel)
        assert(!@nick.is_op?(@channel))
        m = ModSpox::Models::NickMode.find_or_create(:nick_id => @nick.pk, :channel_id => @channel.pk)
        m.set_mode('o')
        assert(@nick.is_op?(@channel))
    end

    def test_channel_voice
        @nick.visible = true
        @nick.add_channel(@channel)
        assert(!@nick.is_voice?(@channel))
        m = ModSpox::Models::NickMode.find_or_create(:nick_id => @nick.pk, :channel_id => @channel.pk)
        m.set_mode('v')
        assert(@nick.is_voice?(@channel))
    end

    def test_nochannel_op_voice
        assert_raise(ModSpox::Exceptions::NotInChannel){@nick.is_voice?(@channel)}
        assert_raise(ModSpox::Exceptions::NotInChannel){@nick.is_op?(@channel)}
    end

    def test_set_mode
        @nick.set_mode('ir')
        assert(@nick.mode_set?('i'))
        assert(@nick.mode_set?('r'))
        assert(!@nick.mode_set?('o'))
    end

    def test_unset_mode
        @nick.set_mode('ir')
        assert(@nick.mode_set?('i'))
        assert(@nick.mode_set?('r'))
        @nick.unset_mode('ir')
        assert(!@nick.mode_set?('i'))
        assert(!@nick.mode_set?('r'))
    end
    

end