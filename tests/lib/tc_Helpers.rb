require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestHelpers < Test::Unit::TestCase
    def setup
        h = BotHolder.instance
        ModSpox::Models::Server.find_or_create(:host => 'some.irc.server.com')
    end
    def test_format_seconds
        inc = {:year => 60 * 60 * 24 * 365,
               :month => 60 * 60 * 24 * 31,
               :week => 60 * 60 * 24 * 7,
               :day => 60 * 60 * 24,
               :hour => 60 * 60,
               :minute => 60,
               :second => 1}
        100.times do |i|
            time = rand(i)
            otime = time
            formatted = []
            inc.each_pair do |name, value|
                val = (time / value).to_i
                if(val > 0)
                    time = time - (val * value)
                    formatted << "#{val} #{val == 1 ? name : "#{name}s"}"
                end
            end
            formatted = formatted.empty? ? '0 seconds' : formatted.join(' ')
            assert_equal(ModSpox::Helpers.format_seconds(otime), formatted)
        end
    end
    
    def test_format_size
        inc = {"byte" => 1024**0,       # 1024^0
               "Kilobyte" => 1024**1,   # 1024^1
               "Megabyte" => 1024**2,   # 1024^2
               "Gigabyte" => 1024**3,   # 1024^3
               "Terabyte" => 1024**4,   # 1024^4
               "Petabyte" => 1024**5,   # 1024^5
               "Exabyte" => 1024**6,    # 1024^6
               "Zettabyte" => 1024**7,  # 1024^7
               "Yottabyte" => 1024**8   # 1024^8
              }
        100.times do |i|
            val = i**rand(i)
            formatted = nil
            inc.each_pair do |name, value|
                v = val / value.to_f
                if(v.to_i > 0)
                    formatted = ("%.3f" % v) + " #{name}#{v == 1 ? '' : 's'}"
                end
            end
            formatted = '0 bytes' if formatted.nil?
            assert_equal(formatted, ModSpox::Helpers.format_size(val))
        end
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
         assert_equal('Error', ModSpox::Helpers.tinyurl(''))
     end

     def test_find_model
         assert_kind_of(ModSpox::Models::Nick, ModSpox::Helpers.find_model('nick'))
         assert_kind_of(ModSpox::Models::Channel, ModSpox::Helpers.find_model('#channel'))
         assert_kind_of(ModSpox::Models::Server, ModSpox::Helpers.find_model('some.irc.server.com'))
         assert_equal('not.a.real.server', ModSpox::Helpers.find_model('not.a.real.server'))
         assert_kind_of(String, '*!*@some.host')
     end
    
    def test_convert_entities
        assert_equal('<p>', ModSpox::Helpers.convert_entities('&lt;p&gt;'))
        assert_equal('hi there', ModSpox::Helpers.convert_entities('hi there'))
    end
    
    def test_load_message
        ModSpox::Helpers.load_message(:internal, :TimerAdd)
        assert(ModSpox::Messages::Internal::TimerAdd)
        assert_raise(ArgumentError){ ModSpox::Helpers.load_message(:foobar, :fee) }
        assert_raise(LoadError){ ModSpox::Helpers.load_message(:internal, :fail) }
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
    
    # test partially lifted from the unit tests in the source
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
        assert_raise(ArgumentError){ ModSpox::Helpers::IdealHumanRandomIterator.new(1) }
        assert_nil(ModSpox::Helpers::IdealHumanRandomIterator.new([]).next)
        assert_equal(0, ModSpox::Helpers::IdealHumanRandomIterator.new([0]).next)
    end
end