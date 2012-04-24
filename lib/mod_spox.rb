%w(
  actionpool 
  actiontimer 
  pipeliner
  baseirc 
  messagefactory 
  splib 
  spockets
).each do |f|
  require f
end

module ModSpox
  VERSION = '0.4.0'
end
