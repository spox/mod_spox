require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestNamesHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :names_start => ':swiftco.wa.us.dal.net 353 spox @ #mod_spox :@pizza_ pizza__ @mod_spox @spox +spex',
                 :names_end => ':swiftco.wa.us.dal.net 366 spox #mod_spox :End of /NAMES list.',
                 :bad => ':fubared 353 fail whale'
                }
    end

    def test_expected
        assert_equal('353', @bot.factory.find_key(@test[:names_start]))
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:names_start])].process(@test[:names_start]))
        assert_equal('366', @bot.factory.find_key(@test[:names_end]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:names_end])].process(@test[:names_end])
        assert_kind_of(ModSpox::Messages::Incoming::Names, result)
        assert_equal('#mod_spox', result.channel.name)
        assert_equal(5, result.nicks.size)
        assert_equal(3, result.ops.size)
        assert_equal(1, result.voiced.size)
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'mod_spox').is_op?(result.channel))
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'pizza_').is_op?(result.channel))
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'spox').is_op?(result.channel))
        assert(!ModSpox::Models::Nick.find_or_create(:nick => 'pizza__').is_op?(result.channel))
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'spex').is_voice?(result.channel))
    end

    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException){@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad])}
    end
end