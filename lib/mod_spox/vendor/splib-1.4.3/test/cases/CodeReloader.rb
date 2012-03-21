require 'splib'
require 'test/unit'
require 'fileutils'

class CodeReloaderTest < Test::Unit::TestCase
  def setup
    @s = File.expand_path("#{__FILE__}/../../samplecode.rb")
    @s1 = File.expand_path("#{__FILE__}/../../samplecode1.rb")
    @s2 = File.expand_path("#{__FILE__}/../../samplecode2.rb")
    Splib.load :CodeReloader
    Splib.load :Constants
    FileUtils.cp @s1, @s
  end
  def teardown
    FileUtils.rm @s, :force => true
  end
  def test_load
    holder = Splib.load_code(@s)
    klass = Splib.find_const('Fu::Bar', [holder])
    obj = klass.new
    assert_equal('hello world', obj.foobar)
  end
  def test_reload
    holder = Splib.load_code(@s)
    klass = Splib.find_const('Fu::Bar', [holder])
    obj = klass.new
    assert(obj.respond_to?(:foobar))
    assert(!obj.respond_to?(:feebar))
    assert_equal('hello world', obj.foobar)
    FileUtils.cp @s2, @s
    holder = Splib.reload_code(holder)
    klass = Splib.find_const('Fu::Bar', [holder])
    obj = klass.new
    assert(obj.respond_to?(:feebar))
    assert(!obj.respond_to?(:foobar))
    assert_equal('goodbye world', obj.feebar)
  end
end