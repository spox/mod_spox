require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestPongHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :wo_server => ':swiftco.wa.us.dal.net PONG swiftco.wa.us.dal.net :FOO',
                 :bad => ':swiftco.wa.us.dal.net PONG swiftco.wa.us.dal.net :FOO'
                }
    end

    def test_wo_server
        assert_equal(:PING, @bot.factory.find_key(@test[:wo_server].dup))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:wo_server].dup)].process(@test[:wo_server].dup)
        assert_kind_of(ModSpox::Messages::Incoming::Ping, result)
        assert_equal(@test[:wo_server], result.raw_content)
        assert_kind_of(String, result.string)
        assert_kind_of(String, result.server)
        assert_equal('not.configured', result.server)
        assert_equal('not.configured', result.string)
    end

    def test_w_server
        assert_equal(:PING, @bot.factory.find_key(@test[:w_server].dup))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:w_server].dup)].process(@test[:w_server].dup)
        assert_kind_of(ModSpox::Messages::Incoming::Ping, result)
        assert_equal(@test[:w_server], result.raw_content)
        assert_kind_of(String, result.string)
        assert_kind_of(String, result.server)
        assert_equal('not.configured', result.server)
        assert_equal('test', result.string)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad].dup)].process(@test[:bad].dup))
    end
end