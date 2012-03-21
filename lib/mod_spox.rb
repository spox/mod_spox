base = "#{File.expand_path(File.dirname(__FILE__))}/mod_spox/vendor"

Dir.new(base).each do |item|
  $LOAD_PATH.unshift "#{base}/#{item}/lib"
end

%w(actionpool actiontimer pipeliner
  baseirc messagefactory splib spockets
).each do |f|
  require f
end

module ModSpox
  VERSION = '0.4.0'
end