require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestPongHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :good => ':swiftco.wa.us.dal.net PONG swiftco.wa.us.dal.net :FOO',
                 :bad => ':bad PONG'
                }
    end

    def test_expected
        assert_equal(:PONG, @bot.factory.find_key(@test[:good].dup))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:good].dup)].process(@test[:good].dup)
        assert_kind_of(ModSpox::Messages::Incoming::Ping, result)
        assert_equal(@test[:good], result.raw_content)
        assert_kind_of(String, result.string)
        assert_kind_of(String, result.server)
        assert_equal('swiftco.wa.us.dal.net', result.server)
        assert_equal('FOO', result.string)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad].dup)].process(@test[:bad].dup))
    end
end