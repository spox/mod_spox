module Splib
    # While not a big fan of monkeypatching, I want to be
    # lazy getting to this
    class ::Float
        def within_delta?(args={})
            raise ArgumentError.new('Missing required argument: :expected') unless args[:expected]
            raise ArgumentError.new('Missing required argument: :delta') unless args[:delta]
            e = args[:expected].to_f
            d = args[:delta].to_f
            self.between?(e-d, e+d)
        end
    end
end