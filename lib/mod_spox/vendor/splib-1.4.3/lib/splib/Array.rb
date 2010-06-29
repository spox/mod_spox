module Splib
    # Only add this if we are in the 1.8 world and no one
    # else has added it yet
    if(Object::RUBY_VERSION < '1.9.0' && ![].respond_to?(:fixed_flatten))
        class ::Array
            # 1.9 compatible flatten method that allows
            # a level parameter
            def fixed_flatten(level = -1)
                arr = self
                case
                when level < 0
                    arr.flatten!
                when level == 0
                    self
                when level > 0
                    arr = []
                    curr = self
                    level.times do
                        curr.each do |elm|
                            if(elm.respond_to?(:to_ary))
                                elm.each{|e| arr << e }
                            else
                                arr << elm
                            end
                        end
                        curr = arr.dup
                    end
                end
                arr
            end
        end
    end
end