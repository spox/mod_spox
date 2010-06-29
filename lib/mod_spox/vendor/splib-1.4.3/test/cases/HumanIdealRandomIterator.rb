require 'splib'
require 'test/unit'

class HumanIdealRandomIteratorTest < Test::Unit::TestCase
    def setup
        Splib.load :HumanIdealRandomIterator
    end

    def test_iterator
        assert_raise(EOFError) do
            100.times do
                results = []
                pool = (0..rand(1000)).to_a
                ideal = Splib::IdealHumanRandomIterator.new(pool)
                (pool.size / 2).times do
                    n = ideal.next()
                    if(results.include?(n))
                        raise ArgumentError.new("Duplicated result")
                    else
                        results << n
                    end
                end
            end
            raise EOFError.new("OK")
        end
        assert_raise(ArgumentError){ Splib::IdealHumanRandomIterator.new(1) }
        assert_nil(Splib::IdealHumanRandomIterator.new([]).next)
        assert_equal(0, Splib::IdealHumanRandomIterator.new([0]).next)
    end
end