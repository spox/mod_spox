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
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Ping')
        require 'mod_spox/handlers/Ping'
        @handler = ModSpox::Handlers::Ping.new({})
    end

    def gather(m)
        @queue << m
    end
    
    def test_indirect
        @bot.factory << @test[:wo_server]
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        check_result(m)
        assert_equal(m.raw_content, @test[:wo_server])
        assert_equal('not.configured', m.server)
        assert_equal('not.configured', m.string)
    end
    
    def test_direct
        m = @handler.process(@test[:w_server])
        check_result(m)
        assert_equal(m.raw_content, @test[:w_server])
        assert_equal('not.configured', m.server)
        assert_equal('test', m.string)
    end
    
    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException) do
            @handler.process(@test[:bad])
        end
    end

    def check_result(result)
        assert_kind_of(ModSpox::Messages::Incoming::Ping, result)
        assert_kind_of(String, result.string)
        assert_kind_of(String, result.server)
    end
end