require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestPingHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :wo_server => 'PING :not.configured',
                 :w_server => ':not.configured PING :test',
                 :bad => 'PING fail whale'
                }
    end

    def test_wo_server
        assert_equal(:PING, @bot.factory.find_key(@test[:wo_server]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:wo_server])].process(@test[:wo_server])
        assert_kind_of(ModSpox::Messages::Incoming::Ping, result)
        assert_equal(@test[:wo_server], result.raw_content)
        assert_kind_of(String, result.string)
        assert_kind_of(String, result.server)
        assert_equal('not.configured', result.server)
        assert_equal('not.configured', result.string)
    end

    def test_w_server
        assert_equal(:PING, @bot.factory.find_key(@test[:w_server]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:w_server])].process(@test[:w_server])
        assert_kind_of(ModSpox::Messages::Incoming::Ping, result)
        assert_equal(@test[:w_server], result.raw_content)
        assert_kind_of(String, result.string)
        assert_kind_of(String, result.server)
        assert_equal('not.configured', result.server)
        assert_equal('test', result.string)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad]))
    end
end