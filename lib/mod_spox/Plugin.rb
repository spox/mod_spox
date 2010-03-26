require 'pipeliner'
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
            [:pipeline, :irc, :timer, :pool].each do |x|
                unless(args.has_key?(x))
                    raise ArgumentEror.new "Expecting #{x}"
                end
            end
            @pipeline = args[:pipeline]
            @irc = args[:irc]
            @timer = args[:timer]
            @pool = args[:pool]
            @pluginmanager = args[:pm]
        end

        # Called before the the plugin is destroyed. Useful
        # for cleaning up references that might be around of this
        # instance so it will not hang around if the plugin is reloaded.
        # NOTE: if overriding this method, call super or ensure you unhook
        # self from the pipeline
        def destroy
            @pipeline.unhook(self)
        end
    end
end
