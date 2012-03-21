module Splib
class << self
  # secs:: Number of seconds to sleep (Use float to provide better actual sleep time)
  def sleep(secs=nil)
    start = Time.now.to_f
    secs.nil? ? Kernel.sleep : Kernel.sleep(secs)
    Time.now.to_f - start
  end
end
end
