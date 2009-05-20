require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestCreatedHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot    
        @test = {
                 :good => ':not.configured 003 spox :This server was created Tue Mar 24 2009 at 15:42:36 PDT',
                 :bad => ':fubared 003 fail whale'
                }
    end

    def test_expected
        assert_equal('003', @bot.factory.find_key(@test[:good]))
        assert_kind_of(ModSpox::Messages::Incoming::Created, @bot.factory.handlers[@bot.factory.find_key(@test[:good])].process(@test[:good]))
        assert_equal(@test[:good], @bot.factory.handlers[@bot.factory.find_key(@test[:good])].process(@test[:good]).raw_content)
        assert_kind_of(Time, @bot.factory.handlers[@bot.factory.find_key(@test[:good])].process(@test[:good]).date)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad]))
    end
end