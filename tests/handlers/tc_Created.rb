require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestCreatedHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :good => ':not.configured 003 spox :This server was created Tue Mar 24 2009 at 15:42:36 PDT',
                 :bad => ':fubared 003 fail whale'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Created')
        require 'mod_spox/handlers/Created'
        @handler = ModSpox::Handlers::Created.new({})
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

    def check_result(m)
        assert_kind_of(ModSpox::Messages::Incoming::Created, m)
        assert_equal(m.raw_content, @test[:good])
    end
end