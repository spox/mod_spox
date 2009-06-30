require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestBadNickHandler < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {:good => 'fail', :bad => 'fail'}
    end

    def teardown
        #nothing#
    end

    def test_expected
        assert_kind_of(ModSpox::Messages::Incoming::BadNick, @bot.factory.handlers[@bot.factory.find_key(@test[:good])].process(@test[:good]))
    end

    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException){@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad])}
    end
end