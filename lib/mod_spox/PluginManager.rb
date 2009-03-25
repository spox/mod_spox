['fileutils',
 'mod_spox/Logger',
 'mod_spox/Pipeline',
 'mod_spox/models/Models',
 'mod_spox/messages/Messages',
 'mod_spox/Plugin',
 'mod_spox/PluginHolder'].each{|f|require f}
module ModSpox

    class PluginManager

        # Hash of plugins. Defined by class name symbol (i.e. Trivia class: plugins[:Trivia])
        attr_reader :plugins

        # pipeline:: Pipeline for messages
        # Create new PluginManager
        def initialize(pipeline)
            @plugins = Hash.new
            @pipeline = pipeline
            @pipeline.hook(self, :load_plugin, :Internal_PluginLoadRequest)
            @pipeline.hook(self, :unload_plugin, :Internal_PluginUnloadRequest)
            @pipeline.hook(self, :reload_plugins, :Internal_PluginReload)
            @pipeline.hook(self, :send_modules, :Internal_PluginModuleRequest)
            @pipeline.hook(self, :plugin_request, :Internal_PluginRequest)
            @plugins_module = Module.new
            @plugin_lock = Mutex.new
            load_plugins
        end

        # message:: Messages::Internal::PluginReload
        # Destroys and reinitializes plugins
        def reload_plugins(message=nil)
            @plugin_lock.synchronize do
                if(!message.nil? && (message.fresh && message.stale))
                    do_unload(message.stale)
                    FileUtils.remove_file(message.stale)
                    FileUtils.copy(message.fresh, BotConfig[:userpluginpath])
                    do_load(message.stale)
                    Logger.info("Completed reload of plugin: #{message.stale}")
                else
                    unload_plugins
                    load_plugins
                end
            end
        end

        # Destroys plugins
        def destroy_plugins
            unload_plugins
        end

        # message:: Messages::Internal::PluginLoadRequest
        # Loads a plugin
        def load_plugin(message)
            begin
                path = !message.name ? "#{BotConfig[:userpluginpath]}/#{message.path.gsub(/^.+\//, '')}" : "#{BotConfig[:userpluginpath]}/#{message.name}"
                begin
                    File.symlink(message.path, path)
                rescue NotImplementedError => boom
                    FileUtils.copy(message.path, path)
                end
                do_load(path)
                @pipeline << Messages::Internal::PluginLoadResponse.new(message.requester, true)
                Logger.info("Loaded new plugin: #{message.path}")
            rescue Object => boom
                Logger.warn("Failed to load plugin: #{message.path} Reason: #{boom}")
                @pipeline << Messages::Internal::PluginLoadResponse.new(message.requester, false)
            end
            @pipeline << Messages::Internal::SignaturesUpdate.new
        end

        # message:: Messages::Internal::PluginUnloadRequest
        # Unloads a plugin
        def unload_plugin(message)
            begin
                do_unload(message.path)
                unless(File.symlink?(message.path))
                    unless(message.name.nil?)
                        FileUtils.copy(message.path, "#{BotConfig[:userpluginpath]}/#{message.name}")
                    end
                end
                File.delete(message.path)
                @pipeline << Messages::Internal::PluginUnloadResponse.new(message.requester, true)
                Logger.info("Unloaded plugin: #{message.path}")
            rescue Object => boom
                Logger.warn("Failed to unload plugin: #{message.path} Reason: #{boom}")
                @pipeline << Messages::Internal::PluginUnloadResponse.new(message.requester, false)
            end
            @pipeline << Messages::Internal::SignaturesUpdate.new
        end

        # message:: Messages::Internal::PluginModuleRequest
        # Sends the plugins module to the requester
        def send_modules(message)
            @pipeline << Messages::Internal::PluginModuleResponse.new(message.requester, @plugins_module)
        end

        # message:: Messages::Internal::PluginRequest
        # Returns a plugin to requesting object
        def plugin_request(message)
            if(@plugins.has_key?(message.plugin))
                response = Messages::Internal::PluginResponse.new(message.requester, @plugins[message.plugin])
            else
                response = Messages::Internal::PluginResponse.new(message.requester, nil)
            end
            @pipeline << response
        end

        def upgrade_plugins
            @plugins[:PluginLoader].plugin.extras_upgrade
        end

        private

        # Loads and initializes plugins
        def load_plugins
            @pipeline << Messages::Internal::TimerClear.new
            Models::Signature.set(:enabled => false)
            [BotConfig[:pluginpath], BotConfig[:userpluginpath]].each do |path|
                Dir.new(path).each do |file|
                    if(file =~ /^[^\.].+\.rb$/)
                        begin
                            do_load("#{path}/#{file}")
                        rescue Object => boom
                            Logger.warn("Failed to load file: #{path}/#{file}. Reason: #{boom}")
                        end
                    end
                end
            end
            @pipeline << Messages::Internal::SignaturesUpdate.new
        end

        # Destroys plugins
        def unload_plugins
            @plugins.each_pair do |sym, holder|
                begin
                    holder.plugin.destroy unless holder.plugin.nil?
                    @pipeline.unhook_plugin(holder.plugin)
                rescue Object => boom
                    Logger.warn("Plugin destruction error: #{boom}")
                end
            end
            @plugins_module = Module.new
            @pipeline << Messages::Internal::TimerClear.new
        end

        # path:: path to plugin file
        # Loads a plugin into the plugin module
        def do_load(path)
            if(File.exists?(path))
                plugins = discover_plugins(path)
                raise PluginMissing.new("Plugin file at: #{path} does not contain a plugin class") if plugins.nil?
                @plugins_module.module_eval(IO.readlines(path).join("\n"))
                begin
                    plugins.each do |plugin|
                        klass = @plugins_module.const_get(plugin)
                        if(@plugins.has_key?(plugin.to_sym))
                            @plugins[plugin.to_sym].set_plugin(klass.new({:pipeline => @pipeline, :plugin_module => @plugins_module}))
                        else
                            @plugins[plugin.to_sym] = PluginHolder.new(klass.new({:pipeline => @pipeline, :plugin_module => @plugins_module}))
                        end
                        Logger.info("Properly initialized new plugin: #{plugin}")
                    end
                    Logger.info("All plugins found at: #{path} have been loaded")
                rescue Object => boom
                    Logger.warn("Plugin loading failed: #{boom}\n#{boom.backtrace.join("\n")}")
                    Logger.warn("All constants loaded from file: #{path} will now be unloaded")
                    do_unload(path)
                end
            else
                raise PluginFileNotFound.new("Failed to find file at: #{path}")
            end
        end

        # path:: path to plugin file
        # Unloads a plugin and all constants from the plugin module
        def do_unload(path)
            if(File.exists?(path))
                discover_plugins(path).each do |plugin|
                    if(@plugins.has_key?(plugin.to_sym))
                        @plugins[plugin.to_sym].plugin.destroy unless @plugins[plugin.to_sym].plugin.nil?
                        @pipeline.unhook_plugin(@plugins[plugin.to_sym].plugin)
                        @plugins[plugin.to_sym].set_plugin(nil)
                        @pipeline << Messages::Internal::TimerClear.new(plugin.to_sym)
                    end
                    Models::Signature.filter(:plugin => plugin.to_s).destroy
                end
                discover_consts(path).each do |const|
                    Logger.info("Removing constant: #{const}")
                    @plugins_module.send(:remove_const, const)
                end
                Logger.info("Removed all constants found in file: #{path}")
            else
                raise PluginFileNotFound.new("Failed to find file at: #{path}")
            end
        end

        # path:: path to plugin
        # Find class names of any plugins within the file at given path
        def discover_plugins(path)
            temp = Module.new
            begin
                temp.module_eval(IO.readlines(path).join("\n"))
                klasses = []
                temp.constants.each do |const|
                    klass = temp.const_get(const)
                    klasses << const if klass < Plugin
                end
                return klasses
            rescue Object => boom
                return nil
            end
        end

        # path:: path to plugin
        # Find all constant names in given path
        def discover_consts(path)
            temp = Module.new
            begin
                temp.module_eval(IO.readlines(path).join("\n"))
                return temp.constants
            rescue Object => boom
                return nil
            end
        end

        class PluginMissing < Exceptions::BotException
        end

        class PluginFileNotFound < Exceptions::BotException
        end

    end

end