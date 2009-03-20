class PluginLoader < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'plugins available', :method => :available_plugins, :group => admin, :desc => 'List all available plugins')
        add_sig(:sig => 'plugins loaded', :method => :loaded_plugins, :group => admin, :desc => 'List all plugins currently loaded')
        add_sig(:sig => 'plugins load (\S+)', :method => :load_plugin, :group => admin, :desc => 'Load the given plugin', :params => [:plugin])
        add_sig(:sig => 'plugins unload (\S+)', :method => :unload_plugin, :group => admin, :desc => 'Unload given plugin', :params => [:plugin])
        add_sig(:sig => 'plugins reload ?(\S+)?', :method => :reload_plugin, :group => admin, :desc => 'Reload single plugin or all plugins if names not provided', :params => [:plugin])
        @pipeline.hook(self, :get_module, :Internal_PluginModuleResponse)
        @plugins_mod = nil
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Output currently available plugins for loading
    def available_plugins(message, params)
        output = ["\2Currently available plugins:\2"]
        find_plugins.each_pair do | plugin, path |
            output << "\2#{plugin}:\2 #{path}"
        end
        reply message.replyto, output
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Output currently loaded plugins
    def loaded_plugins(message, params)
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "\2Currently loaded plugins:\2 #{plugin_list.join(', ')}")
    end
    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Load the given plugin
    def load_plugin(message, params)
        plugins = find_plugins
        if(plugins.has_key?(params[:plugin].to_sym))
            name = plugin_discovery(BotConfig[:pluginextraspath]).keys.include?(params[:plugin].to_sym) ? nil : "#{params[:plugin]}.rb"
            @pipeline << Messages::Internal::PluginLoadRequest.new(self, plugins[params[:plugin].to_sym], name)
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Okay")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find plugin: #{params[:plugin]}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Unload the given plugin
    def unload_plugin(message, params)
        path = loaded_path(params[:plugin].to_sym)
        unless(path.nil?)
            name = plugin_discovery(BotConfig[:pluginextraspath]).keys.include?(params[:plugin].to_sym) ? nil : ".#{params[:plugin]}.rb"
            @pipeline << Messages::Internal::PluginUnloadRequest.new(self, path, name)
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Okay")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find loaded plugin named: #{params[:plugin]}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Reloads plugins
    def reload_plugin(message, params)
        if(params[:plugin])
            users = plugin_discovery(BotConfig[:userpluginpath])
            extras = plugin_discovery(BotConfig[:pluginextraspath])
            fresh = nil
            stale = nil
            users.each_pair{|name, path| stale = path if name == params[:plugin]}
            extras.each_pair{|name, path| fresh = path if name == params[:plugin]}
            if(fresh && stale)
                @pipeline << Messages::Internal::PluginReload.new(fresh, stale)
                reply message.replyto, "Reloading #{params[:plugin]}"
            else
                reply message.replyto, "\2Error:\2 Failed to find new and stale versions of: #{params[:plugin]}"
            end
        else
            @pipeline << Messages::Internal::PluginReload.new
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, 'Full plugin reload requested')
        end
    end

    # message:: ModSpox::Messages::Internal::PluginModuleResponse
    # Receives the plugins module
    def get_module(message)
        @plugins_mod = message.module
    end

    # Upgrades extra plugins to latest version
    def extras_upgrade
        Logger.info("Starting plugin upgrade to current version: #{$BOTVERSION}")
        extras = plugin_discovery(BotConfig[:pluginextraspath])
        pl = plugin_list
        extras.keys.each{|d| extras.delete(d) unless pl.include?(d)}
        extras.keys.each do |plugin|
            path = loaded_path(plugin)
            @pipeline << Messages::Internal::PluginUnloadRequest.new(self, path, plugin)
        end
        Logger.info('Waiting for plugins to complete unloading...')
        sleep(3)
        Logger.info('Loading active plugins back into the bot')
        extras.each do |name, path|
            @pipeline << Messages::Internal::PluginLoadRequest.new(self, path)
        end
        Logger.info("Plugin upgrade is now complete. Upgraded to version: #{$BOTVERSION}")
    end

    private

    # Returns the list of currently loaded plugins
    def plugin_list
        plug = []
        @pipeline << Messages::Internal::PluginModuleRequest.new(self)
        sleep(0.01) while @plugins_mod.nil?
        @plugins_mod.constants.sort.each do |const|
            klass = @plugins_mod.const_get(const)
            if(klass < Plugin)
                plug << const
            end
        end
        @plugins_mod = nil
        return plug
    end

    # Finds available plugins for loading
    def find_plugins
        users = plugin_discovery(BotConfig[:userpluginpath])
        extras = plugin_discovery(BotConfig[:pluginextraspath])
        plugins = users.merge(extras)
        plugin_list.each do |name|
            plugins.delete(name) if plugins.has_key?(name)
        end
        return plugins
    end

    # path:: path to directory
    # Discovers any plugins within the files in the given path
    def plugin_discovery(path)
        plugins = Hash.new
        Dir.new(path).each do |file|
            begin
                next unless file =~ /\.rb$/
                sandbox = Module.new
                sandbox.module_eval(IO.readlines("#{path}/#{file}").join("\n"))
                sandbox.constants.each do |const|
                    klass = sandbox.const_get(const)
                    plugins[const.to_sym] = "#{path}/#{file}" if klass < Plugin
                end
            rescue Object => boom
                Logger.warn("Failed to parse file: #{path}/#{file}. Reason: #{boom}\n#{boom.backtrace.join("\n")}")
                next
            end
        end
        return plugins
    end

    # name:: plugin name
    # Returns the file path the given plugin originated from
    def loaded_path(name)
        Dir.new(BotConfig[:userpluginpath]).each do |file|
            begin
                next unless file =~ /\.rb$/
                sandbox = Module.new
                sandbox.module_eval(IO.readlines("#{BotConfig[:userpluginpath]}/#{file}").join("\n"))
                sandbox.constants.each do |const|
                    return "#{BotConfig[:userpluginpath]}/#{file}" if const == name
                end
            rescue Object => boom
                Logger.warn("Failed to load file: #{file}. Reason: #{boom}")
            end
        end
        return nil
    end

end