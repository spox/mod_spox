require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestNickModel < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        @bot = h.bot
        @nick = ModSpox::Models::Nick.find_or_create(:nick => 'foobar')
        @group = ModSpox::Models::Group.find_or_create(:name => 'test')
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
        assert(@nick.auth.groups.include?(@group))
    end

end