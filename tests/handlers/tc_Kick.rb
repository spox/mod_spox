require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestKickHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :good => ':spax!~spox@host KICK #m spox :foo',
                 :bad => ':fubared KICK fail whale'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Kick')
        require 'mod_spox/handlers/Kick'
        @handler = ModSpox::Handlers::Kick.new({})
    end

    def gather(m)
        @queue << m
    end
    
    def test_indirect
        @bot.factory << @test[:good]
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        check_result(m)
    end
    
    def test_direct
        check_result(@handler.process(@test[:good]))
    end
    
    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException) do
            @handler.process(@test[:bad])
        end
    end

    def check_result(result)
        assert_kind_of(ModSpox::Messages::Incoming::Kick, result)
        assert_equal(@test[:good], result.raw_content)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('#m', result.channel.name)
        assert_kind_of(ModSpox::Models::Nick, result.kickee)
        assert_equal('spox', result.kickee.nick)
        assert_kind_of(ModSpox::Models::Nick, result.kicker)
        assert_equal('spax', result.kicker.nick)
        assert_kind_of(String, result.reason)
        assert_equal('foo', result.reason)
    end

end