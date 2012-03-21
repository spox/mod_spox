$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'splib/BasicTimer'
require 'thread'

class BasicTimerTest < Test::Unit::TestCase
  def setup
    @timer = Splib::BasicTimer.new
  end

  def test_add_single
    output = Queue.new
    b = @timer.add(:period => 0.1){ output << :foo }
    assert_kind_of(Proc, b)
    sleep(1.01)
    assert_equal(10, output.size)
  end

  def test_remove_single
    output = Queue.new
    b = @timer.add(:period => 0.1){ output << :foo }
    assert_kind_of(Proc, b)
    sleep(0.11)
    assert_equal(1, output.size)
    @timer.remove(b)
    sleep(0.11)
    assert_equal(1, output.size)
  end

  def test_add_multiple
    output = Queue.new
    @timer.add(:period => 0.1){ output << :foo }
    @timer.add(:period => 0.2){ output << :fee }
    @timer.add(:period => 0.5){ output << :fubar }
    sleep(0.51)
    assert_equal(8, output.size)
  end

  def test_remove_multiple
    output = Queue.new
    a = @timer.add(:period => 0.1){ output << :foo }
    b = @timer.add(:period => 0.2){ output << :foo }
    c = @timer.add(:period => 0.1){ output << :foo }
    sleep(0.21)
    assert_equal(5, output.size)
    @timer.remove(b)
    sleep(0.21)
    assert_equal(9, output.size)
  end
end
