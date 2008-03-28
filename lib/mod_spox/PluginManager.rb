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
            @plugins_module = Module.new
            load_plugins
        end
        
        # message:: Messages::Internal::PluginReload
        # Destroys and reinitializes plugins
        def reload_plugins(mesasge=nil)
            unload_plugins
            load_plugins
        end
        
        # Destroys plugins
        def destroy_plugins
            unload_plugins
        end
        
        # message:: Messages::Internal::PluginLoadRequest
        # Loads a plugin
        def load_plugin(message)
            begin
                Logger.log("THE MESSAGE NAME IS: #{message.name}")
                path = message.name.nil? ? BotConfig[:userpluginpath] : "#{BotConfig[:userpluginpath]}/#{message.name}"
                File.copy(message.path, path)
                reload_plugins
                @pipeline << Messages::Internal::PluginLoadResponse.new(message.requester, true)
                Logger.log("Loaded new plugin: #{message.path}", 10)
            rescue Object => boom
                Logger.log("Failed to load plugin: #{message.path}", 10)
                @pipeline << Messages::Internal::PluginLoadResponse.new(message.requester, false)
            end
        end
        
        # message:: Messages::Internal::PluginUnloadRequest
        # Unloads a plugin
        def unload_plugin(message)
            begin
                unless(message.name.nil?)
                    File.copy(message.path, "#{BotConfig[:userpluginpath]}/#{message.name}")
                end
                File.unlink(message.path)
                reload_plugins
                @pipeline << Messages::Internal::PluginUnloadResponse.new(message.requester, true)
                Logger.log("Unloaded plugin: #{message.path}", 10)
            rescue Object => boom
                Logger.log("Failed to unload plugin: #{message.path} Reason: #{boom}", 10)
                @pipeline << Messages::Internal::PluginUnloadResponse.new(message.requester, false)
            end
        end
        
        # message:: Messages::Internal::PluginModuleRequest
        # Sends the plugins module to the requester
        def send_modules(message)
            @pipeline << Messages::Internal::PluginModuleResponse.new(message.requester, @plugins_module)
        end
        
        private
        
        # Loads and initializes plugins
        def load_plugins
            @pipeline << Messages::Internal::TimerClear.new
            [BotConfig[:pluginpath], BotConfig[:userpluginpath]].each{|path|
                Dir.new(path).each{|file|
                    if(file =~ /^[^\.].+\.rb$/)
                        @plugins_module.module_eval(IO.readlines("#{path}/#{file}").join("\n"))
                    end
                }
            }
            @plugins_module.constants.each{|const|
                klass = @plugins_module.const_get(const)
                if(klass < Plugin)
                    @plugins[const.to_sym] = klass.new(@pipeline)
                    Logger.log("Initialized new plugin: #{const}", 15)
                end
            }
            @pipeline << Messages::Internal::SignaturesUpdate.new
        end
        
        # Destroys plugins
        def unload_plugins
            @plugins.each_pair{|sym, plugin| plugin.destroy; @pipeline.unhook_plugin(plugin)}
            @plugins.clear
            Models::Signature.delete_all
            @plugins_module = Module.new
            @pipeline << Messages::Internal::TimerClear.new
        end
    
    end

end