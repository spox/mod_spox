# Quick loader for all models
Dir.new(File.dirname(__FILE__)).each do |f|
    require File.dirname(__FILE__) + '/' + f if f =~ /\.rb$/
end