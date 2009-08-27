require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestQuitHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :w_message => ':spox!~spox@host QUIT :Ping timeout',
                 :wo_message => ':spox!~spox@host QUIT :',
                 :bad => ':not.configured QUIT fail whale'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Quit')
        require 'mod_spox/handlers/Quit'
        @handler = ModSpox::Handlers::Quit.new({})
    end

    def gather(m)
        @queue << m
    end
    
    def test_indirect
        @bot.factory << @test[:wo_message]
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        check_result(m)
        assert_equal(@test[:wo_message], m.raw_content)
        assert_equal('', m.message)
    end
    
    def test_direct
        m = @handler.process(@test[:w_message])
        check_result(m)
        assert_equal('Ping timeout', m.message)
        assert_equal(@test[:w_message], m.raw_content)
    end
    
    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException) do
            @handler.process(@test[:bad])
        end
    end

    def check_result(result)
        assert_kind_of(ModSpox::Messages::Incoming::Quit, result)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
        assert_equal('spox', result.nick.nick)
        assert_kind_of(String, result.message)
    end

end