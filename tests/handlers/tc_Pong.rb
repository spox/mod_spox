require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestPongHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :good => ':swiftco.wa.us.dal.net PONG swiftco.wa.us.dal.net :FOO',
                 :bad => ':bad PONG fail'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Pong')
        require 'mod_spox/handlers/Pong'
        @handler = ModSpox::Handlers::Pong.new({})
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
        assert_kind_of(ModSpox::Messages::Incoming::Pong, result)
        assert_equal(@test[:good], result.raw_content)
        assert_kind_of(String, result.string)
        assert_kind_of(String, result.server)
        assert_equal('swiftco.wa.us.dal.net', result.server)
        assert_equal('FOO', result.string)
    end
end