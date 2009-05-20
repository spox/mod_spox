require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestQuitHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :w_message => ':spox!~spox@host QUIT :Ping timeout',
                 :wo_message => ':spox!~spox@host QUIT :',
                 :bad => ':not.configured QUIT fail whale'
                }
    end

    def test_wo_message
        assert_equal(:QUIT, @bot.factory.find_key(@test[:wo_message]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:wo_message])].process(@test[:wo_message])
        assert_kind_of(ModSpox::Messages::Incoming::Quit, result)
        assert_equal(@test[:wo_message], result.raw_content)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
        assert_equal('spox', result.nick.nick)
        assert_kind_of(String, result.message)
        assert_equal('', result.message)
    end

    def test_w_message
        assert_equal(:QUIT, @bot.factory.find_key(@test[:w_message]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:w_message])].process(@test[:w_message])
        assert_kind_of(ModSpox::Messages::Incoming::Quit, result)
        assert_equal(@test[:w_message], result.raw_content)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
        assert_equal('spox', result.nick.nick)
        assert_kind_of(String, result.message)
        assert_equal('Ping timeout', result.message)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad]))
    end
end