require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestWhoHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                    :good => [],
                    :bad => ':host 319 fail whale'
                }
        @test[:good] << ':swiftco.wa.us.dal.net 311 spox spox ~spox myhost.com * :spox'
        @test[:good] << ':swiftco.wa.us.dal.net 319 spox spox :@#php #python +#!php +#ruby #mysql @#mod_spox'
        @test[:good] << ':swiftco.wa.us.dal.net 312 spox spox swiftco.wa.us.dal.net :www.swiftco.net - Swift Communications'
        @test[:good] << ':swiftco.wa.us.dal.net 307 spox spox :has identified for this nick'
        @test[:good] << ':swiftco.wa.us.dal.net 317 spox spox 176 1242140666 :seconds idle, signon time'
        @test[:good] << ':swiftco.wa.us.dal.net 318 spox spox :End of /WHOIS list.'
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, :Incoming_Whois)
        @voice = ['#ruby', '#!php']
        @ops = ['#php', '#mod_spox']
        nick = ModSpox::Models::Nick.find_or_create(:nick => 'spox')
        nick.auth.services = true
        nick.auth.save
        @con = Time.at(1242140666)
    end
    
    def gather(m)
        @queue << m
    end

    def test_expected
        5.times{ @bot.factory << @test[:good].shift }
        sleep(0.5) # wait for much longer than needed to check queue
        assert_equal(0, @queue.size)
        @bot.factory << @test[:good].shift
        sleep(0.1) # make sure the message is waiting for us
        assert_equal(1, @queue.size)
        m = @queue.pop
        assert_kind_of(ModSpox::Messages::Incoming::Whois, m)
        assert_equal('spox', m.nick.nick)
        assert_equal(6, m.channels.size)
        assert(!m.nick.auth.services)
        @voice.each do |chan|
            assert(m.nick.is_voice?(ModSpox::Helpers.find_model(chan)))
        end
        @ops.each do |chan|
            assert(m.nick.is_op?(ModSpox::Helpers.find_model(chan)))
        end
        assert_equal(@con, m.nick.connected_at)
        assert_equal(176, m.nick.seconds_idle)
        assert_equal('swiftco.wa.us.dal.net', m.nick.connected_to)
        assert_equal('~spox', m.nick.username)
        assert_equal('myhost.com', m.nick.host)
        assert_equal('spox', m.nick.real_name)
    end

    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException){@bot.factory.handlers[@bot.factory.find_key(@test[:bad].dup)].process(@test[:bad].dup)}
    end
end