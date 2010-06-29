require 'splib'
require 'test/unit'

class ConversionsTest < Test::Unit::TestCase
    def setup
        Splib.load :Conversions
    end

    def test_format_seconds
        inc = [{:year => 60 * 60 * 24 * 365},
               {:month => 60 * 60 * 24 * 31},
               {:week => 60 * 60 * 24 * 7},
               {:day => 60 * 60 * 24},
               {:hour => 60 * 60},
               {:minute => 60},
               {:second => 1}]
        100.times do |i|
            time = rand(i)
            otime = time
            formatted = []
            inc.each do |v|
                v.each_pair do |name, value|
                    val = (time / value).to_i
                    if(val > 0)
                        time = time - (val * value)
                        formatted << "#{val} #{val == 1 ? name : "#{name}s"}"
                    end
                end
            end
            formatted = formatted.empty? ? '0 seconds' : formatted.join(' ')
            assert_equal(formatted, Splib.format_seconds(otime))
        end   
    end

    def test_format_size
        inc = [{"byte" => 1024**0},       # 1024^0
               {"Kilobyte" => 1024**1},   # 1024^1
               {"Megabyte" => 1024**2},   # 1024^2
               {"Gigabyte" => 1024**3},   # 1024^3
               {"Terabyte" => 1024**4},   # 1024^4
               {"Petabyte" => 1024**5},   # 1024^5
               {"Exabyte" => 1024**6},    # 1024^6
               {"Zettabyte" => 1024**7},  # 1024^7
               {"Yottabyte" => 1024**8}   # 1024^8
               ]
        100.times do |i|
            val = i**rand(i)
            formatted = nil
            inc.each do |v|
                v.each_pair do |name, value|
                    v = val / value.to_f
                    if(v.to_i > 0)
                        formatted = ("%.2f " % v) + " #{name}#{v == 1 ? '' : 's'}".strip
                    end
                end
            end
            formatted = '0 bytes' if formatted.nil?
            assert_equal(formatted, Splib.format_size(val))
        end 
    end
end