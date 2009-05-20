require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestKickHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :good => ':spax!~spox@host KICK #m spox :foo',
                 :bad => ':fubared KICK fail whale'
                }
    end

    def test_expected
        assert_equal(:KICK, @bot.factory.find_key(@test[:good]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:good])].process(@test[:good])
        assert_kind_of(ModSpox::Messages::Incoming::Kick, result)
        assert_equal(@test[:good], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('#m', result.channel.name)
        assert_kind_of(ModSpox::Models::Nick, result.kickee)
        assert_equal('spox', result.kickee.nick)
        assert_kind_of(ModSpox::Models::Nick, result.kicker)
        assert_equal('spax', result.kicker.nick)
        assert_kind_of(String, result.reason)
        assert_equal('foo', result.reason)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad]))
    end
end