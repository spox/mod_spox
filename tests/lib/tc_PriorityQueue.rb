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
        5.times{|i| @queue.priority_queue('slot1', "test#{i}") }
        5.times{|i| @queue.priority_queue('slot2', "fubar#{i}") }
        @queue.direct_queue('first')
        assert_equal('first', @queue.pop)
    end

end