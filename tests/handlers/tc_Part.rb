require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestPartHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :w_message => ':mod_spox!~mod_spox@host PART #m :part message',
                 :wo_message => ':mod_spox!~mod_spox@host PART #m :',
                 :bad => ':bad PART fail'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Part')
        require 'mod_spox/handlers/Part'
        @handler = ModSpox::Handlers::Part.new({})
    end

    def gather(m)
        @queue << m
    end
    
    def test_indirect
        @bot.factory << @test[:w_message]
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        check_result(m)
        assert_equal('part message', m.reason)
        assert_equal(m.raw_content, @test[:w_message])
    end
    
    def test_direct
        m = @handler.process(@test[:wo_message])
        check_result(m)
        assert(m.reason.empty?)
        assert_equal(m.raw_content, @test[:wo_message])
    end
    
    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException) do
            @handler.process(@test[:bad])
        end
    end

    def check_result(result)
        assert_kind_of(ModSpox::Messages::Incoming::Part, result)
        assert_kind_of(String, result.reason)
        assert_kind_of(ModSpox::Models::Nick, result.nick)
        assert_kind_of(ModSpox::Models::Channel, result.channel)
        assert_equal('mod_spox', result.nick.nick)
        assert_equal('#m', result.channel.name)
    end
end