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
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Privmsg')
        require 'mod_spox/handlers/Privmsg'
        @handler = ModSpox::Handlers::Privmsg.new({})
    end

    def gather(m)
        @queue << m
    end
    
    def test_indirect
        @bot.factory << @test[:nick_to_channel]
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        check_nick2chan(m)
    end
    
    def test_nick
        check_nick2nick(@handler.process(@test[:nick_to_nick]))
    end
    
    def test_chan_ad
        check_nick2chanad(@handler.process(@test[:nick_to_channel_addressed]))
    end
    
    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException) do
            @handler.process(@test[:bad])
        end
    end

    def check_nick2chan(result)
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

    def check_nick2chanad(result)
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

    def check_nick2nick(result)
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
end