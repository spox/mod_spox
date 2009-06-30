require "#{File.dirname(__FILE__)}/../BotHolder.rb"
require 'digest/sha1'

class TestAuthModel < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        @bot = h.bot
        @nick = ModSpox::Models::Nick.find_or_create(:nick => 'foobar')
    end
    
    def teardown
        @nick.auth.authed = false
    end
    
    def test_create
        assert_kind_of(ModSpox::Models::Auth, @nick.auth)
    end
    
    def test_password
        password = 'password'
        c_pass = Digest::SHA1.hexdigest(password)
        auth = @nick.auth
        auth.password = password
        auth.save
        auth.refresh
        assert_equal(c_pass, auth.password)
        @nick.auth.check_password(password)
        assert(@nick.auth.authed)
    end
    
    def test_services
        auth = @nick.auth
        auth.services = true
        auth.services_identified = true
        auth.save
        assert(@nick.auth.authed)
    end

end