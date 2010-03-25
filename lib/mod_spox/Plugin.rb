require 'pipeliner/pipeline'
require 'baseirc'

module ModSpox
    # Base class from which all plugins must descend
    class Plugin
        # args:: Argument hash.
        # :pipeline:: Pipeliner::Pipeline
        # :irc:: BaseIRC::IRC
        # :timer:: ActionTimer::Timer
        # :pool:: ActionPool::Pool
        # Create new plugin instance
        def initialize(args={})
            @pipeline = args[:pipeline]
            @irc = args[:irc]
            @timer = args[:timer]
            @pool = args[:pool]
        end
    end
end
