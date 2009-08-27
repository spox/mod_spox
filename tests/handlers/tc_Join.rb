require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestJoinHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot    
        @test = {
                 :good => ':mod_spox!~mod_spox@host JOIN :#m',
                 :bad => ':fubared JOIN fail whale'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Join')
        require 'mod_spox/handlers/Join'
        @handler = ModSpox::Handlers::Join.new({})
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
        assert_kind_of(ModSpox::Messages::Incoming::Join, m)
        assert_equal(m.raw_content, @test[:good])
        assert_kind_of(ModSpox::Models::Channel, m.channel)
        assert_kind_of(ModSpox::Models::Nick, m.nick)
        assert_equal('#m', m.channel.name)
        assert_equal('mod_spox', m.nick.nick)
        assert_equal('host', m.nick.host)
        assert_equal('host', m.nick.address)
        assert_equal('~mod_spox', m.nick.username)
        assert_equal('mod_spox!~mod_spox@host', m.nick.source)
        assert(m.nick.visible)
    end
end