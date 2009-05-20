require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestPrivmsgHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :nick_to_channel => ':spox!~spox@host PRIVMSG #m :foobar',
                 :nick_to_nick => ':spox!~spox@host PRIVMSG mod_spox :foobar',
                 :nick_to_channel_addressed => ':spox!~spox@host PRIVMSG #m :mod_spox: foobar',
                 :bad => ':fubared PRIVMSG fail whale'
                }
    end

    def test_nick_to_channel
        assert_equal(:PRIVMSG, @bot.factory.find_key(@test[:nick_to_channel]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:nick_to_channel])].process(@test[:nick_to_channel])
        assert_kind_of(ModSpox::Messages::Incoming::Privmsg, result)
        assert_equal(@test[:nick_to_channel], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.target)
        assert_equal('#m', result.target.name)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('spox', result.source.nick)
        assert_kind_of(String, result.message)
        assert_equal('foobar', result.message)
        assert(!result.is_private?)
        assert(result.is_public?)
        assert(!result.addressed?)
        assert(!result.is_action?)
        assert(!result.is_colored?)
        assert(!result.is_ctcp?)
        assert(!result.is_dcc?)
        assert_equal(result.message_nocolor, result.message)
        assert_equal(result.target, result.replyto)
    end

    def test_nick_to_channel_addressed
        assert_equal(:PRIVMSG, @bot.factory.find_key(@test[:nick_to_channel_addressed]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:nick_to_channel_addressed])].process(@test[:nick_to_channel_addressed])
        assert_kind_of(ModSpox::Messages::Incoming::Privmsg, result)
        assert_equal(@test[:nick_to_channel_addressed], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.target)
        assert_equal('#m', result.target.name)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('spox', result.source.nick)
        assert_kind_of(String, result.message)
        assert_equal('mod_spox: foobar', result.message)
        assert(!result.is_private?)
        assert(result.is_public?)
        assert(result.addressed?)
        assert(!result.is_action?)
        assert(!result.is_colored?)
        assert(!result.is_ctcp?)
        assert(!result.is_dcc?)
        assert_equal(result.message_nocolor, result.message)
        assert_equal(result.target, result.replyto)
    end

    def test_nick_to_nick
        assert_equal(:PRIVMSG, @bot.factory.find_key(@test[:nick_to_nick]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:nick_to_nick])].process(@test[:nick_to_nick])
        assert_kind_of(ModSpox::Messages::Incoming::Privmsg, result)
        assert_equal(@test[:nick_to_nick], result.raw_content)
        assert_kind_of(ModSpox::Models::Nick, result.target)
        assert_equal('mod_spox', result.target.nick)
        assert_kind_of(ModSpox::Models::Nick, result.source)
        assert_equal('spox', result.source.nick)
        assert_kind_of(String, result.message)
        assert_equal('foobar', result.message)
        assert(result.is_private?)
        assert(!result.is_public?)
        assert(result.addressed?)
        assert(!result.is_action?)
        assert(!result.is_colored?)
        assert(!result.is_ctcp?)
        assert(!result.is_dcc?)
        assert_equal(result.message_nocolor, result.message)
        assert_equal(result.source, result.replyto)
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad]))
    end
end