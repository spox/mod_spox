require "#{File.dirname(__FILE__)}/../BotHolder.rb"

class TestBotConfig < Test::Unit::TestCase

    def setup
        h = BotHolder.instance
        @queue = ModSpox::PriorityQueue.new
    end

    def test_basic
        @queue.direct_queue('test1')
        assert_equal('test1', @queue.pop)
        @queue.priority_queue('slot1', 'test2')
        assert_equal('test2', @queue.pop)
    end

    def test_prioritizer
        # load the queue up
        @queue.priority_queue('*slot0', 'last')
        5.times{ @queue.priority_queue('slot1', "test") }
        5.times{ @queue.priority_queue('slot2', "fubar") }
        @queue.direct_queue('first')
        assert_equal('first', @queue.pop)
        5.times do
            assert_equal('test', @queue.pop)
            assert_equal('fubar', @queue.pop)
        end
        assert_equal('last', @queue.pop)
    end

end