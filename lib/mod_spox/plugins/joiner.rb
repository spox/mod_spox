module ModSpox
module Plugins
class Joiner < ModSpox::Plugin
  def setup
    @pipeline.hook(Messages::Initialized, self, :add_triggers)
  end

  def destroy
  end
  
  def add_triggers(m)
    @pipeline << {:signature => {:regexp => /^join (\S+)$/, :call => {:object => self, :method => :join}, :matches => [:channel]}}
    Logger.debug "Sent trigger registration information for joiner"
  end

  def join(m, args)
    @irc.join args[:channel]
  end
end
end
end