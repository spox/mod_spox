require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestHelpers < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        ModSpox::Models::Server.find_or_create(:host => 'some.irc.server.com', :connected => true)
    end
    
    def test_format_seconds
        assert_equal(ModSpox::Helpers.format_seconds(2), "2 seconds")
        assert_equal(ModSpox::Helpers.format_seconds(122), "2 minutes 2 seconds")
        assert_equal(ModSpox::Helpers.format_seconds(234432), "2 days 17 hours 7 minutes 12 seconds")
        assert_equal(ModSpox::Helpers.format_seconds(9883432), "4 months 2 days 9 hours 23 minutes 52 seconds")
        assert_equal(ModSpox::Helpers.format_seconds(79067456), "2 years 8 months 2 weeks 5 days 3 hours 10 minutes 56 seconds")
    end
    
    def test_format_size
        assert_equal(ModSpox::Helpers.format_size(1), '  1.000 byte')
        assert_equal(ModSpox::Helpers.format_size(2), '  2.000 bytes')
        assert_equal(ModSpox::Helpers.format_size(5000), '  4.883 Kilobytes')
        assert_equal(ModSpox::Helpers.format_size(9999999), '  9.537 Megabytes')
        assert_equal(ModSpox::Helpers.format_size(99999990000), ' 93.132 Gigabytes')
        assert_equal(ModSpox::Helpers.format_size(9999999000088), '  9.095 Terabytes')
        assert_equal(ModSpox::Helpers.format_size(9999999000088777666), '  8.674 Exabytes')
    end
    
     def test_safe_exec
         assert_raise(IOError) do
             ModSpox::Helpers.safe_exec('echo test', 10, 1)
         end
         assert_raise(Timeout::Error) do
             ModSpox::Helpers.safe_exec('while [ true ]; do true; done;', 1)
         end
         assert_equal("test\n", ModSpox::Helpers.safe_exec('echo test'))
     end

     def test_tinyurl
         assert_equal('http://tinyurl.com/1c2', ModSpox::Helpers.tinyurl('http://www.google.com'))
     end

     def test_find_model
         assert_kind_of(ModSpox::Models::Nick, ModSpox::Helpers.find_model('nick'))
         assert_kind_of(ModSpox::Models::Channel, ModSpox::Helpers.find_model('#channel'))
         assert_kind_of(ModSpox::Models::Server, ModSpox::Helpers.find_model('some.irc.server.com'))
         assert_nil(ModSpox::Helpers.find_model('not.a.real.server'))
         assert_kind_of(String, '*!*@some.host')
     end
    
    def test_convert_entities
        assert_equal('<p>', ModSpox::Helpers.convert_entities('&lt;p&gt;'))
    end
    
    def test_load_message
        ModSpox::Helpers.load_message(:internal, :TimerAdd)
        assert(ModSpox::Messages::Internal::TimerAdd)
    end
     
     def test_type_of?
        ModSpox::Helpers.load_message(:internal, :HaltBot)
        m = ModSpox::Messages::Internal::HaltBot.new
        assert(ModSpox::Helpers.type_of?(m, Object))
        assert(ModSpox::Helpers.type_of?(m, ModSpox))
        assert(ModSpox::Helpers.type_of?(m, ModSpox::Messages))
        assert(ModSpox::Helpers.type_of?(m, ModSpox::Messages::Internal))
        assert(ModSpox::Helpers.type_of?(m, ModSpox::Messages::Internal::HaltBot))
        assert(ModSpox::Helpers.type_of?(m, :ModSpox_Messages_Internal_HaltBot, true))
        assert(ModSpox::Helpers.type_of?(m, :Internal_HaltBot, true))
        assert(ModSpox::Helpers.type_of?(m, :Internal, true))
        assert(!ModSpox::Helpers.type_of?(m, String))
     end
     
    def test_find_const
        ModSpox::Helpers.load_message(:internal, :HaltBot)
        assert(ModSpox::Messages::Internal::HaltBot)
        assert_equal(ModSpox::Messages::Internal::HaltBot, ModSpox::Helpers.find_const('ModSpox::Messages::Internal::HaltBot'))
        assert_equal(ModSpox::Messages::Internal::HaltBot, ModSpox::Helpers.find_const('Internal::HaltBot'))
        assert_equal('Incoming::UnknownType', ModSpox::Helpers.find_const('Incoming::UnknownType'))
    end
    
    # these tests lifted from the unit tests in the source
    # provided by Ryan "pizza_" Flynn
    # Class and tests found in: http://github.com/pizza/algodict

    def test_random
        assert_raise(ModSpox::Exceptions::GeneralException) do
            100.times do
                results = []
                pool = (0..rand(1000)).to_a
                ideal = ModSpox::Helpers::IdealHumanRandomIterator.new(pool)
                (pool.size / 2).times do
                    n = ideal.next()
                    if(results.include?(n))
                        raise Exception.new("Duplicated result")
                    else
                        results << n
                    end
                end
            end
            raise ModSpox::Exceptions::GeneralException.new("OK")
        end
    end
end