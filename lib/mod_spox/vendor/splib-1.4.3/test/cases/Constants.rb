require 'splib'
require 'test/unit'

module Foo
    module Bar
        class Fubar
        end
    end
end

class ConstantsTest < Test::Unit::TestCase
    def setup
        Splib.load :Constants
    end
    def test_find_const
        mod = Module.new
        mod.class_eval("
            module Fu
                class Bar
                end
            end"
        )
        assert_equal(String, Splib.find_const('String'))
        assert_equal(Foo::Bar::Fubar, Splib.find_const('Foo::Bar::Fubar'))
        assert_match(/<.+?>::Fu::Bar/, Splib.find_const('Fu::Bar', [mod]).to_s)
    end
    def test_type_of?
        mod = Module.new
        mod.class_eval("
            module Fu
                class Bar
                end
            end"
        )
        assert(Splib.type_of?('test', 'String'))
        assert(Splib.type_of?('test', String))
        assert(Splib.type_of?('test', 'Object'))
        assert(Splib.type_of?('test', Object))
        fubar = Splib.find_const('Fu::Bar', [mod]).new
        assert(Splib.type_of?(fubar, 'Fu::Bar'))
        assert(Splib.type_of?(fubar, Object))
    end
end