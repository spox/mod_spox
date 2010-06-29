require 'splib'
require 'test/unit'

class MonitorTest < Test::Unit::TestCase
    Splib.load :Monitor
    Splib.load :Sleep
    def setup
        @monitor = Splib::Monitor.new
    end

    def test_wait
        t = []
        5.times{ t << Thread.new{ @monitor.wait } }
        Splib.sleep(0.1) # give threads a chance to wait
        t.each do |thread|
            assert(thread.alive?)
            assert(thread.stop?)
        end
    end

    def test_wait_timeout
        t = []
        o = Queue.new
        5.times{ t << Thread.new{ @monitor.wait(0.1); o << 1 } }
        Splib.sleep(0.3)
        assert_equal(5, o.size)
    end

    def test_signal
        output = Queue.new
        t = []
        5.times{ t << Thread.new{ @monitor.wait; output << 1 } }
        Splib.sleep(0.01)
        t.each do |thread|
            assert(thread.alive?)
            assert(thread.stop?)
        end
        assert(output.empty?)
        @monitor.signal
        Splib.sleep(0.01)
        assert_equal(4, t.select{|th|th.alive?}.size)
        assert_equal(1, output.size)
        assert_equal(1, output.pop)
    end

    def test_broadcast
        output = Queue.new
        t = []
        5.times{ t << Thread.new{ @monitor.wait; output << 1 } }
        Splib.sleep(0.01)
        t.each do |thread|
            assert(thread.alive?)
            assert(thread.stop?)
        end
        assert_equal(5, t.size)
        assert(output.empty?)
        @monitor.broadcast
        Splib.sleep(0.1)
        assert_equal(5, output.size)
        5.times{ assert_equal(1, output.pop) }
        assert_equal(5, t.select{|th|!th.alive?}.size)
    end

    def test_synchronize_broadcast
        output = Queue.new
        t = []
        5.times{ t << Thread.new{ @monitor.wait; output << 1 } }
        Splib.sleep(0.01)
        t.each do |thread|
            assert(thread.alive?)
            assert(thread.stop?)
        end
        assert_equal(5, t.size)
        assert(output.empty?)
        @monitor.synchronize{ @monitor.broadcast }
        Splib.sleep(0.1)
        assert_equal(5, output.size)
        5.times{ assert_equal(1, output.pop) }
        assert_equal(5, t.select{|th|!th.alive?}.size)
    end
    
    def test_multi_lock
        @monitor.synchronize do
            @monitor.synchronize do
                @monitor.lock
                @monitor.synchronize do
                    true
                end
                @monitor.unlock
            end
        end
    end

    def test_wait_while
        stop = true
        t = Thread.new{ @monitor.wait_while{ stop } }
        Splib.sleep(0.01)
        assert(t.alive?)
        assert(t.stop?)
        @monitor.signal
        Splib.sleep(0.01)
        assert(t.alive?)
        assert(t.stop?)
        @monitor.broadcast
        Splib.sleep(0.01)
        assert(t.alive?)
        assert(t.stop?)
        stop = false
        @monitor.signal
        Splib.sleep(0.01)
        assert(!t.alive?)
        assert(t.stop?)
    end

    def test_wait_until
        stop = false
        done = false
        t = Thread.new{ @monitor.wait_until{ stop }; done = true; }
        Splib.sleep(0.01)
        assert(t.alive?)
        assert(t.stop?)
        @monitor.signal
        Splib.sleep(0.01)
        assert(t.alive?)
        assert(t.stop?)
        @monitor.broadcast
        Splib.sleep(0.01)
        assert(t.alive?)
        assert(t.stop?)
        stop = true
        @monitor.signal
        Splib.sleep(0.1)
        assert(done)
    end

    def test_waiters
        t = []
        (rand(20)+1).times{ t << Thread.new{ @monitor.wait } }
        Splib.sleep(0.1)
        assert_equal(t.size, @monitor.waiters)
        @monitor.broadcast
        Splib.sleep(0.1)
        assert_equal(0, @monitor.waiters)
    end

    def test_lock_unlock
        t = []
        output = []
        3.times{|i| t << Thread.new{ @monitor.lock; Splib.sleep(0.1); output << i; @monitor.unlock;}}
        Splib.sleep(0.12)
        assert_equal(1, output.size)
        Splib.sleep(0.12)
        assert_equal(2, output.size)
        Splib.sleep(0.12)
        assert_equal(3, output.size)
        assert(!t.any?{|th|th.alive?})
        3.times{|i|assert_equal(i, output.shift)}
    end

    def test_lock_unlock_wakeup
        complete = false
        t1 = Thread.new{@monitor.lock; Splib.sleep(0.1); @monitor.unlock}
        Splib.sleep(0.01)
        t2 = Thread.new{@monitor.lock; complete = true; @monitor.unlock}
        assert(!complete)
        assert(t1.alive?)
        t2.wakeup
        Thread.pass
        assert(!complete)
        Splib.sleep(0.15)
        assert(complete)
    end

    def synchronize
        t = []
        output = []
        5.times{|i| t << Thread.new{ @monitor.lock; Splib.sleep(i/100.0); output << i; @monitor.unlock;}}
        @monitor.synchronize{ output << :done }
        Splib.sleep(0.5)
        assert_equal(6, output.size)
    end

    def test_try_lock
        assert(@monitor.try_lock)
        assert(@monitor.locked?)
        assert(@monitor.try_lock)
        Thread.new{ assert(!@monitor.try_lock) }
        @monitor.unlock
        assert(!@monitor.locked?)
        Thread.new{ assert(@monitor.try_lock); @monitor.unlock }
    end

end