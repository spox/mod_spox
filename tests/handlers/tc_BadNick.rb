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
        assert_kind_of(ModSpox::Messages::Incoming::BadNick, @handler.process(@test[:good]))
    end

    def test_unexpected
        assert_nil(@handler.process(@test[:bad]))
    end
end