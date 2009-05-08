require "#{File.dirname(__FILE__)}/BotHolder.rb"

class TestModeHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot    
        @test = {
                 :good => ':spax!~spox@host MODE #m +o spax',
                 :bad => ':fubared MODE fail whale'
                }
    end

    def test_expected
        assert_equal(:MODE, @bot.factory.find_key(@test[:good].dup))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:good].dup)].process(@test[:good].dup)
        assert_kind_of(ModSpox::Messages::Incoming::Mode, result)
        assert_equal(@test[:good], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('#m', result.channel.name)
        assert_kind_of(ModSpox::Models::Nick, result.target)
        assert_equal('spax', result.target.nick)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('spax', result.source.nick)
        assert_kind_of(String, result.mode)
        assert_equal('+o', result.mode)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad].dup)].process(@test[:bad].dup))
    end
end