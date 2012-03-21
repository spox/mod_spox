require 'splib'
require 'test/unit'

class FloatTest < Test::Unit::TestCase
  def setup
    Splib.load :Float
  end
  
  def test_delta
    t = 3.2
    assert(3.204.within_delta?(:expected => t, :delta => 0.1))
    assert(3.3.within_delta?(:expected => t, :delta => 0.1))
    assert(3.3.within_delta?(:expected => t, :delta => 0.1))
    assert(3.1.within_delta?(:expected => t, :delta => 0.1))
    assert(!(3.09.within_delta?(:expected => t, :delta => 0.1)))
    assert(!(3.31.within_delta?(:expected => t, :delta => 0.1)))
    assert(3.0.within_delta?(:expected => 4, :delta => 1))
    assert(!(3.0.within_delta?(:expected => 5, :delta => 1)))
  end
end