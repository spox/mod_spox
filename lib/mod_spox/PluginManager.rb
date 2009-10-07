['fileutils',
 'mod_spox/Logger',
 'mod_spox/Pipeline',
 'mod_spox/models/Models',
 'mod_spox/messages/Messages',
 'mod_spox/Plugin',
 'mod_spox/PluginHolder',
 'mod_spox/Exceptions',
 'mod_spox/messages/internal/QueueSocket',
 'mod_spox/messages/internal/UnqueueSocket',
 'mod_spox/messages/internal/PluginLoadResponse',
 'mod_spox/messages/internal/SignaturesUpdate',
 'mod_spox/messages/internal/PluginUnloadResponse',
 'mod_spox/messages/internal/PluginModuleResponse',
 'mod_spox/messages/internal/PluginResponse',
 'mod_spox/messages/internal/TimerClear',
 'mod_spox/messages/internal/PluginsReady'].each{|f|require f}
 
module ModSpox

    class PluginManager

        include Exceptions

        # Hash of plugins. Defined by class name symbol (i.e. Trivia class: plugins[:Trivia])
        attr_reader :plugins

        # pipeline:: Pipeline for messages
        # Create new PluginManager
        def initialize(pipeline)
            @plugin_map = Hash.new
            @plugins = Hash.new
            @pipeline = pipeline
            @pipeline.hook(self, :load_plugin, ModSpox::Messages::Internal::PluginLoadRequest)
            @pipeline.hook(self, :unload_plugin, ModSpox::Messages::Internal::PluginUnloadRequest)
            @pipeline.hook(self, :reload_plugins, ModSpox::Messages::Internal::PluginReload)
            @pipeline.hook(self, :send_modules, ModSpox::Messages::Internal::PluginModuleRequest)
            @pipeline.hook(self, :plugin_request, ModSpox::Messages::Internal::PluginRequest)
            @plugins_module = Module.new
            @plugin_lock = Mutex.new
            load_plugins
        end

        # message:: Messages::Internal::PluginReload
        # Destroys and reinitializes plugins
        def reload_plugins(message=nil)
            @pipeline << Messages::Internal::QueueSocket.new
            begin
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
            rescue Object => boom
                Logger.error("PluginManager caught error on plugin reload: #{boom}")
            ensure
                @pipeline << Messages::Internal::UnqueueSocket.new
            end
        end

        # Destroys plugins
        def destroy_plugins
            unload_plugins
        end

        # message:: Messages::Internal::PluginLoadRequest
        # Loads a plugin
        def load_plugin(message)
            @pipeline << Messages::Internal::QueueSocket.new
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
            ensure
                @pipeline << Messages::Internal::SignaturesUpdate.new
                @pipeline << Messages::Internal::UnqueueSocket.new
            end
        end

        # message:: Messages::Internal::PluginUnloadRequest
        # Unloads a plugin
        def unload_plugin(message)
            @pipeline << Messages::Internal::QueueSocket.new
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
            ensure
                @pipeline << Messages::Internal::UnqueueSocket.new
                @pipeline << Messages::Internal::SignaturesUpdate.new
            end
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
            [@plugin_map[:default], @plugin_map[:user]].each do |listing|
                listing.keys.each{|plugin| do_load(plugin)}
            end
            user_plugins.each{|plugin| do_load(plugin)}
            @pipeline << Messages::Internal::SignaturesUpdate.new
            @pipeline << Messages::Internal::PluginsReady.new
            true
        end

        # Destroys plugins
        def unload_plugins
            @plugins.keys.each{|plugin| do_unload(plugin, false)}
            Models::Signature.filter(:plugin => plugin.to_s).update(:enabled => false)
            @plugins_module = Module.new
            @pipeline << Messages::Internal::TimerClear.new
            true
        end

        # plugin_name:: Name of plugin to unload
        # clean:: Perform clean up stuff
        # Unloads plugin from the bot
        def do_unload(plugin_name, clean=true)
            plugin = plugin_name.to_sym
            if(@plugins.has_key?(plugin))
                unless(@plugins[plugin].plugin.nil?)
                    @plugins[plugin].plugin.destroy
                    @pipeline.unhook_plugin(@plugins[plugin].plugin)
                    @plugins[plugin.to_sym].set_plugin(nil)
                    @pipeline << Messages::Internal::TimerClear.new(plugin.to_sym) if clean
                end
            end
            discover_constants(plugin_path(plugin_name)).each do |const|
                Logger.info("Removing constant: #{const}")
                @plugins_module.send(:remove_const, const)
            end
            Models::Signature.filter(:plugin => plugin.to_s).update(:enabled => false) if clean
            true
        end

        # plugin_name:: Name of plugin to load
        # Locates the location of this plugin and loads it into the bot
        def do_load(plugin_name)
            path = find_path(plugin_name)
            raise PluginFileNotFound.new("Failed to find plugin file for plugin named: #{plugin_name}")
            @plugins_module.module_eval(IO.binread(path))
            klass = @plugins_module.const_get(plugin_name)
            obj = klass.new({:pipeline => @pipeline, :plugin_module => @plugin_module})
            if(@plugins.has_key?(plugin_name.to_sym))
                @plugins[plugin_name.to_sym].set_plugin(obj)
            else
                @plugins[plugin_name.to_sym] = PluginHolder.new(obj)
            end
            true
        end

        # path:: path to directory of plugins
        # Discover all valid plugins in given directory. Use this information
        # to return a hash of: {:plugin_name => 'plugin/path'}
        def discover_plugins(path)
            raise ArgumentError.new('Valid directory path required') unless File.directory?(path)
            found = {}
            Dir.new(path).each do |file|
                begin
                    next unless file[-3,3] == '.rb'
                    discover_constants("#{path}/#{file}", true).each do |klass|
                        found[klass.to_sym] = "#{path}/#{file}"
                    end
                rescue Object => boom
                    Logger.warn("Failed to parse plugin file: #{path}/#{file} - Reason: #{boom}"
                end
            end
            return found
        end

        # Generates a map of plugin locations
        def map_plugins
            @plugin_map.clear
            [[BotConfig[:pluginpath], :default], [BotConfig[:userpluginpath], :user], [BotConfig[:pluginextraspath], :extra]].each do |base|
                @plugin_map[base[1]] = discover_plugins(base[0])
            end
            true
        end

        # name:: name of plugin
        # return path or nil
        def plugin_path(name)
            name = name.to_sym unless name.is_a?(Symbol)
            @plugin_map.values.each do |plugs|
                return plugs[sym] if plugs[sym]
            end
            nil
        end

        # path:: path to plugin file
        # plugins:: return only plugin constants
        # Find all constants in a given ruby file
        def discover_constants(path, plugins=false)
            raise ArgumentError.new('Failed to locate plugin file') unless File.exists?(path)
            consts = []
            sandbox = Module.new
            sandbox.module_eval(IO.binread(path))
            sandbox.constants.each{|klass| consts << klass.to_sym if !plugins || (plugins && klass < ModSpox::Plugin)}
            return consts
        end

        def add_user_plugin(name)
            plugs = Models::Setting.find_or_create(:name => 'load_plugins')
            list = plugs.value.nil? ? Array.new : plugs.value
            list << name unless list.include?(name)
            plugs.value = list
            plugs.save
        end

        def user_plugins
            plugs = Models::Setting.find_or_create(:name => 'load_plugins')
            plugs.value = Array.new if plugs.value.nil?
            plugs.save
            return plugs.value.dup
        end

    end

end