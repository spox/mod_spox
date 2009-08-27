require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestNamesHandler < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @bot = h.bot
        @test = {
                 :names_start => ':swiftco.wa.us.dal.net 353 spox @ #mod_spox :@pizza_ pizza__ @mod_spox @spox +spex',
                 :names_end => ':swiftco.wa.us.dal.net 366 spox #mod_spox :End of /NAMES list.',
                 :bad => ':fubared 353 fail whale'
                }
        @queue = Queue.new
        @bot.pipeline.hook(self, :gather, 'ModSpox::Messages::Incoming::Names')
        require 'mod_spox/handlers/Names'
        @handler = ModSpox::Handlers::Names.new({})
    end

    def gather(m)
        @queue << m
    end
    
    def test_indirect
        @bot.factory << @test[:names_start]
        @bot.factory << @test[:names_end]
        sleep(0.1)
        assert_equal(1, @queue.size)
        m = @queue.pop
        check_result(m)
    end
    
    def test_direct
        assert_nil(@handler.process(@test[:names_start]))
        check_result(@handler.process(@test[:names_end]))
    end
    
    def test_unexpected
        assert_raise(ModSpox::Exceptions::GeneralException) do
            @handler.process(@test[:bad])
        end
    end

    def check_result(result)
        assert_kind_of(ModSpox::Messages::Incoming::Names, result)
        assert_equal('#mod_spox', result.channel.name)
        assert_equal(5, result.nicks.size)
        assert_equal(3, result.ops.size)
        assert_equal(1, result.voiced.size)
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'mod_spox').is_op?(result.channel))
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'pizza_').is_op?(result.channel))
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'spox').is_op?(result.channel))
        assert(!ModSpox::Models::Nick.find_or_create(:nick => 'pizza__').is_op?(result.channel))
        assert(ModSpox::Models::Nick.find_or_create(:nick => 'spex').is_voice?(result.channel))
    end
end