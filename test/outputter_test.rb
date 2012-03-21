
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'mod_spox/Outputter'

class OutputterTest < Test::Unit::TestCase

  def setup
    @q = Splib::PriorityQueue.new
    @o = ModSpox::Outputter.new(@q)
  end

  def teardown
    @o.stop
    @q = nil
    @o = nil
  end

  def test_start
    @o.start
    assert_raise(RuntimeError) do
      @o.start
    end
  end

  def test_simple
    @o.start
    @o.queue << 'test'
    assert_equal('test', @q.pop)
    @o.queue << 'foo'
    @o.queue << 'bar'
    assert_equal('foo', @q.pop)
    assert_equal('bar', @q.pop)
  end

  def test_priority
    @o.start
    @o.queue << 'fubar'
    @o.queue << 'QUIT :fubar'
    @o.queue << 'QUIT :done'
    @o.queue << 'PRIVMSG #a :hi'
    @o.queue << 'PRIVMSG #b :test'
    @o.queue << 'PRIVMSG #a :foo'
    @o.queue << 'test'
    sleep(0.01)
    assert_equal('fubar', @q.pop)
    assert_equal('QUIT :fubar', @q.pop)
    assert_equal('PRIVMSG #a :hi', @q.pop)
    assert_equal('PRIVMSG #b :test', @q.pop)
    assert_equal('test', @q.pop)
    assert_equal('QUIT :done', @q.pop)
    assert_equal('PRIVMSG #a :foo', @q.pop)
  end

end
