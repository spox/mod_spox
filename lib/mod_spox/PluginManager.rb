require 'fileutils'
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
            load_plugins
        end
        
        # message:: Messages::Internal::PluginReload
        # Destroys and reinitializes plugins
        def reload_plugins(message=nil)
            if(message.fresh && message.stale)
                names = discover_plugins(message.stale)
                names.each do |name| 
                    Logger.log("Removing #{name} from the plugins module")
                    @plugins_module.send(:remove_const, name)
                end
                FileUtils.remove_file(message.stale)
                FileUtils.copy(message.fresh, BotConfig[:userpluginpath])
                @plugins_module.module_eval(IO.readlines(message.fresh).join("\n"))
            else
                unload_plugins
                load_plugins
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
                path = !message.name ? BotConfig[:userpluginpath] : "#{BotConfig[:userpluginpath]}/#{message.name}"
                FileUtils.copy(message.path, path)
                @plugins_module.module_eval(IO.readlines(path).join("\n"))
                @pipeline << Messages::Internal::PluginLoadResponse.new(message.requester, true)
                Logger.log("Loaded new plugin: #{message.path}", 10)
            rescue Object => boom
                Logger.log("Failed to load plugin: #{message.path} Reason: #{boom}", 10)
                @pipeline << Messages::Internal::PluginLoadResponse.new(message.requester, false)
            end
        end
        
        # message:: Messages::Internal::PluginUnloadRequest
        # Unloads a plugin
        def unload_plugin(message)
            begin
                names = discover_plugins(message.path)
                unless(message.name.nil?)
                    FileUtils.copy(message.path, "#{BotConfig[:userpluginpath]}/#{message.name}")
                end
                FileUtils.remove_file(message.path)
                unless(names.nil?)
                    names.each do |name| 
                        Logger.log("Removing #{name} from the plugins module")
                        @plugins_module.send(:remove_const, name)
                    end
                    Logger.log('Plugin was unloaded without a full reload', 99)
                else
                    reload_plugins
                    Logger.log('Plugins were reloaded on the unload plugin command', 99)
                end
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
        
        private
        
        # Loads and initializes plugins
        def load_plugins
            @pipeline << Messages::Internal::TimerClear.new
            [BotConfig[:pluginpath], BotConfig[:userpluginpath]].each{|path|
                Dir.new(path).each{|file|
                    if(file =~ /^[^\.].+\.rb$/)
                        begin
                            @plugins_module.module_eval(IO.readlines("#{path}/#{file}").join("\n"))
                        rescue Object => boom
                            Logger.log("Failed to load file: #{path}/#{file}. Reason: #{boom}")
                        end
                    end
                }
            }
            @plugins_module.constants.each{|const|
                klass = @plugins_module.const_get(const)
                if(klass < Plugin)
                    begin
                        @plugins[const.to_sym] = klass.new(@pipeline)
                        Logger.log("Initialized new plugin: #{const}", 15)
                    rescue Object => boom
                        Logger.log("Failed to initialize plugin #{const}. Reason: #{boom}")
                    end
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
    
    end

end