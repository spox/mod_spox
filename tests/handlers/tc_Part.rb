require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestPartHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :w_message => ':mod_spox!~mod_spox@host PART #m :part message',
                 :wo_message => ':mod_spox!~mod_spox@host PART #m :',
                 :bad => ':bad PART fail'
                }
    end

    def test_w_message
        assert_equal(:PART, @bot.factory.find_key(@test[:w_message]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:w_message])].process(@test[:w_message])
        assert_kind_of(ModSpox::Messages::Incoming::Part, result)
        assert_equal(@test[:w_message], result.raw_content)
        assert_kind_of(String, result.reason)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('mod_spox', result.nick.nick)
        assert_equal('#m', result.channel.name)
        assert_equal('part message', result.reason)
    end

    def test_wo_message
        assert_equal(:PART, @bot.factory.find_key(@test[:wo_message]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:wo_message])].process(@test[:wo_message])
        assert_kind_of(ModSpox::Messages::Incoming::Part, result)
        assert_equal(@test[:wo_message], result.raw_content)
        assert_kind_of(String, result.reason)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('mod_spox', result.nick.nick)
        assert_equal('#m', result.channel.name)
        assert(result.reason.empty?)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad]))
    end
end