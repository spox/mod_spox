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
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Invite')
        require 'mod_spox/handlers/Invite'
        @handler = ModSpox::Handlers::Invite.new({})
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