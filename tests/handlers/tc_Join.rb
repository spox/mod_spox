require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestJoinHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot    
        @test = {
                 :good => ':mod_spox!~mod_spox@host JOIN :#m',
                 :bad => ':fubared JOIN fail whale'
                }
    end

    def test_expected
        assert_equal(:JOIN, @bot.factory.find_key(@test[:good]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:good])].process(@test[:good])
        assert_kind_of(ModSpox::Messages::Incoming::Join, result)
        assert_equal(@test[:good], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
        assert_equal('#m', result.channel.name)
        assert_equal('mod_spox', result.nick.nick)
        assert_equal('host', result.nick.host)
        assert_equal('host', result.nick.address)
        assert_equal('~mod_spox', result.nick.username)
        assert_equal('mod_spox!~mod_spox@host', result.nick.source)
        assert(result.nick.visible)
    end

    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException){@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad])}
    end
end