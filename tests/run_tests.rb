require 'test/unit'
['handlers', 'models'].each{|d|
    Dir.new("#{File.dirname(__FILE__)}/#{d}").each{|f|
        require "#{File.dirname(__FILE__)}/#{d}/#{f}" if f[-2..f.size] == 'rb'
    }
}