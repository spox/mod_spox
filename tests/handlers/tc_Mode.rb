require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestModeHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot    
        @test = {
                 :set_single => ':spax!~spox@host MODE #m +o spax',
                 :set_double => ':spax!~spox@host MODE #m +oo spax spex',
                 :set_channel => ':spax!~spox@host MODE #m +s',
                 :set_self => ':mod_spox MODE mod_spox :+iw',
                 :bad => ':fubared MODE fail whale'
                }
    end

    def test_single
        assert_equal(:MODE, @bot.factory.find_key(@test[:set_single]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:set_single])].process(@test[:set_single])
        assert_kind_of(ModSpox::Messages::Incoming::Mode, result)
        assert_equal(@test[:set_single], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('#m', result.channel.name)
        assert_kind_of(ModSpox::Models::Nick, result.target)
        assert_equal('spax', result.target.nick)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('spax', result.source.nick)
        assert_kind_of(String, result.mode)
        assert_equal('+o', result.mode)
        assert(result.target.is_op?(result.channel))
    end

    def test_double
        assert_equal(:MODE, @bot.factory.find_key(@test[:set_double]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:set_double])].process(@test[:set_double])
        assert_kind_of(ModSpox::Messages::Incoming::Mode, result)
        assert_equal(@test[:set_double], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('#m', result.channel.name)
        assert_kind_of(Array, result.target)
        assert_equal('spax', result.target[0].nick)
        assert_equal('spex', result.target[1].nick)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('spax', result.source.nick)
        assert_kind_of(String, result.mode)
        assert_equal('+oo', result.mode)
        assert(result.target[0].is_op?(result.channel))
        assert(result.target[1].is_op?(result.channel))
    end

    def test_channel
        assert_equal(:MODE, @bot.factory.find_key(@test[:set_channel]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:set_channel])].process(@test[:set_channel])
        assert_kind_of(ModSpox::Messages::Incoming::Mode, result)
        assert_equal(@test[:set_channel], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('#m', result.channel.name)
        assert_nil(result.target)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('spax', result.source.nick)
        assert_kind_of(String, result.mode)
        assert_equal('+s', result.mode)
        assert(result.channel.set?('s'))
    end
    
    def test_self
        assert_equal(:MODE, @bot.factory.find_key(@test[:set_self]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:set_self])].process(@test[:set_self])
        assert_kind_of(ModSpox::Messages::Incoming::Mode, result)
        assert_equal(@test[:set_self], result.raw_content)
        assert_nil(result.channel)
        assert_kind_of(ModSpox::Models::Nick, result.target)
        assert_equal('mod_spox', result.target.nick)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('mod_spox', result.source.nick)
        assert_kind_of(String, result.mode)
        assert_equal('+iw', result.mode)
        assert(result.target.mode_set?('i'))
        assert(result.target.mode_set?('w'))
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad]))
    end
end