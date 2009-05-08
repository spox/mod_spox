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
        assert_equal(:JOIN, @bot.factory.find_key(@test[:good].dup))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:good].dup)].process(@test[:good].dup)
        assert_kind_of(ModSpox::Messages::Incoming::Join, result)
        assert_equal(@test[:good], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad].dup)].process(@test[:bad].dup))
    end
end