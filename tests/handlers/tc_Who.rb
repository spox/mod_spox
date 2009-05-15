require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestWhoHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                    :good => [],
                    :bad => ':host 352 fail whale'
                }
        @test[:good] << ':host 352 spox #mod_spox ~pizza_ host.1 punch.va.us.dal.net pizza_ H@ :5 pizza_'
        @test[:good] << ':host 352 spox #mod_spox ~pizza_ host.2 punch.va.us.dal.net pizza__ H :5 pizza_'
        @test[:good] << ':host 352 spox #mod_spox ~mod_spox host.3 mozilla.se.eu.dal.net mod_spox H@ :6 mod_spox IRC bot'
        @test[:good] << ':host 352 spox #mod_spox ~spox host.4 swiftco.wa.us.dal.net spox H@ :0 spox'
        @test[:good] << ':host 315 spox #mod_spox :End of /WHO list.'
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, :Incoming_Who)
        @nicks = ['pizza_', 'pizza__', 'spox', 'mod_spox']
        @ops = ['pizza_', 'spox', 'mod_spox']
    end
    
    def gather(m)
        @queue << m
    end

    def test_expected
        4.times{ @bot.factory << @test[:good].shift }
        sleep(0.5) # wait for much longer than needed to check queue
        assert_equal(0, @queue.size)
        @bot.factory << @test[:good].shift
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        assert_kind_of(ModSpox::Messages::Incoming::Who, m)
        assert_kind_of(ModSpox::Models::Channel, m.location)
        assert_equal('#mod_spox', m.location.name)
        assert_kind_of(Array, m.nicks)
        assert_equal(4, m.nicks.size)
        m.nicks.each do |nick|
            assert(@nicks.include?(nick.nick))
            assert(nick.channels.map{|c|c.name}.include?('#mod_spox'))
            assert_equal(@ops.include?(nick.nick), nick.is_op?(m.location))
        end
    end

    def test_unexpected
        assert_nil(@bot.factory.handlers[@bot.factory.find_key(@test[:bad].dup)].process(@test[:bad].dup))
    end
end