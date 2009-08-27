require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestNickHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :good => ':spox!~spox@some.random.host NICK :flock_of_deer',
                 :bad => ':bad NICK fail'
                }
        @nick = ModSpox::Models::Nick.find_or_create(:nick => 'spox')
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Nick')
        require 'mod_spox/handlers/Nick'
        @handler = ModSpox::Handlers::Nick.new({})
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
        assert_kind_of(ModSpox::Messages::Incoming::Nick, m)
        assert_equal(@test[:good], m.raw_content)
        assert_kind_of(ModSpox::Models::Nick, m.new_nick)
        assert_kind_of(ModSpox::Models::Nick, m.original_nick)
        assert_equal('spox', m.original_nick.nick)
        assert_equal('flock_of_deer', m.new_nick.nick)
        assert_equal(m.raw_content, @test[:good])
    end
    
    def test_info_move
        @nick.address = 'some.random.host'
        @nick.username = '~spox'
        @nick.real_name = 'foobar'
        @nick.save
        m = @handler.process(@test[:good])
        assert_kind_of(ModSpox::Messages::Incoming::Nick, m)
        assert_equal('spox', m.original_nick.nick)
        assert_equal('flock_of_deer', m.new_nick.nick)
        assert_equal('some.random.host', m.new_nick.address)
        assert_equal('~spox', m.new_nick.username)
        assert_equal('foobar', m.new_nick.real_name)
    end
    
    def test_mode_move
        c = ModSpox::Models::Channel.find_or_create(:name => '#test')
        @nick.add_channel(c)
        mode = ModSpox::Models::NickMode.find_or_create(:nick_id => @nick.pk, :channel_id => c.pk)
        mode.set_mode('o')
        m = @handler.process(@test[:good])
        assert_kind_of(ModSpox::Messages::Incoming::Nick, m)
        assert_equal(0, m.original_nick.channels.size)
        assert(m.new_nick.channels.size > 0)
        assert(m.new_nick.channels.include?(c))
        assert(m.new_nick.is_op?(c))
    end
end