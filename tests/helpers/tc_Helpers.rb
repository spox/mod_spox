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
    
#     def test_load_message
#     end
#     
#      def test_type_of?
#      end
#     
#     def test_find_const
#     end
#     
    # Add tests here for randomizer #
end