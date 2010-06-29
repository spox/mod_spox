require 'splib'
require 'test/unit'

class ArrayTest < Test::Unit::TestCase
    def setup
        Splib.load :Array
    end

    def test_flatten_original
        if([].respond_to?(:fixed_flatten))
            arr = [1,2,[3,[4,5],6],7]
            assert_equal(arr, arr.fixed_flatten(0))
            assert_equal(arr.flatten, arr.fixed_flatten)
        end
    end
end