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
    def initialize(bot, timer, manager)
      @pipeline = bot.pipeline
      @irc = bot.irc
      @timer = timer
      @pool = bot.pool
      @plugin_manager = manager
      @bot = bot
      if(self.respond_to?(:add_triggers))
        @pipeline.hook(Messages::Initialized, self, :add_triggers)
        @pipeline.hook(Messages::PluginReload, self, :add_triggers)
      end
      setup
    end

    # This is used for any setup the plugin may need to perform
    def setup
    end

    # Called before the the plugin is destroyed. Useful
    # for cleaning up references that might be around of this
    # instance so it will not hang around if the plugin is reloaded.
    # NOTE: if overriding this method, call super or ensure you unhook
    # self from the pipeline
    def destroy
      @pipeline.unhook(self)
    end

    def current_nick
      info[:nick]
    end

    def info
      _info = {}
      store = PStore.new("#{ModSpox.config_dir}/bot.pstore")
      store.transaction do
        _info[:nick] = store[:nick]
        _info[:username] = store[:username]
        _info[:realname] = store[:realname]
      end
      _info
    end
  end
end
