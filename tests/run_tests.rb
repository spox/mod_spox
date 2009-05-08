require 'test/unit'
Dir.new("#{File.dirname(__FILE__)}/handlers").each{|f|
    require "#{File.dirname(__FILE__)}/handlers/#{f}" if f[-2..f.size] == 'rb'
}