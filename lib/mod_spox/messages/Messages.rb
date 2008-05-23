# Lazy loader for messages
['incoming', 'outgoing', 'internal'].each do |dir|
    Dir.new(File.dirname(__FILE__) + '/' + dir).each do |file|
        require File.dirname(__FILE__) + '/' + dir + '/' + file if file =~ /\.rb$/
    end
end