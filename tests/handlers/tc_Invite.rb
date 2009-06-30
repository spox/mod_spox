require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestInviteHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot    
        @test = {
                    :good => ':spox!~spox@host INVITE spex :#m',
                    :bad => ':fail INVITE whale'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, :Incoming_Invite)
    end
    
    def gather(m)
        @queue << m
    end

    def test_direct
        assert_equal(:INVITE, @bot.factory.find_key(@test[:good]))
        result = @bot.factory.handlers[@bot.factory.find_key(@test[:good])].process(@test[:good])
        check_result(result)
    end
    
    def test_indirect
        @bot.factory << @test[:good]
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        check_result(m)
    end
    
    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException){@bot.factory.handlers[@bot.factory.find_key(@test[:bad])].process(@test[:bad])}
    end
    
    private
    
    def check_result(m)
        assert_kind_of(ModSpox::Messages::Incoming::Invite, m)
        assert_kind_of(ModSpox::Models::Nick, m.source)
        assert_kind_of(ModSpox::Models::Nick, m.target)
        assert_kind_of(ModSpox::Models::Channel, m.channel)
        assert_equal('spox', m.source.nick)
        assert_equal('spex', m.target.nick)
        assert_equal('#m', m.channel.name)
        assert_equal(@test[:good], m.raw_content)
    end
end