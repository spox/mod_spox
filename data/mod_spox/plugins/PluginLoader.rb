['mod_spox/messages/outgoing/Privmsg',
 'mod_spox/messages/internal/PluginLoadRequest',
 'mod_spox/messages/internal/PluginUnloadRequest',
 'mod_spox/messages/internal/PluginReload',
 'mod_spox/messages/internal/PluginModuleRequest'].each{|f|require f}
class PluginLoader < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'plugins available', :method => :available_plugins, :group => admin, :desc => 'List all available plugins')
        add_sig(:sig => 'plugins loaded', :method => :loaded_plugins, :group => admin, :desc => 'List all plugins currently loaded')
        add_sig(:sig => 'plugins load (\S+)', :method => :load_plugin, :group => admin, :desc => 'Load the given plugin', :params => [:plugin])
        add_sig(:sig => 'plugins unload (\S+)', :method => :unload_plugin, :group => admin, :desc => 'Unload given plugin', :params => [:plugin])
        add_sig(:sig => 'plugins reload ?(\S+)?', :method => :reload_plugin, :group => admin, :desc => 'Reload single plugin or all plugins if names not provided', :params => [:plugin])
        @pipeline.hook(self, :respond_load, ModSpox::Messages::Internal::PluginsLoadResponse)
        @pipeline.hook(self, :respond_unload, ModSpox::Messages::Internal::PluginsUnloadResponse)
        @lock = Mutex.new
        @info = {}
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Output currently available plugins for loading
    # TODO: This still needs to be fixed
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
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "\2Currently loaded plugins:\2 #{@plugin_manager.plugins.keys.sort.join(', ')}")
    end
    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Load the given plugin
    def load_plugin(m, params)
        @lock.lock
        @pipeline << Messages::Internal::PluginLoadRequest(self, params[:plugin].to_sym)
        @info = {:reply => m.replyto, :plugin => params[:plugin]}
        information m.replyto, "Requesting load of plugin: #{params[:plugin]}"
    end
    
    def respond_load(m)
        begin
            raise "Not waiting for a reply" if @info.nil?
            if(m.success)
                information @info[:reply], "Successfully loaded plugin: #{@info[:plugin]}"
            else
                error @info[:reply], "Failed to load plugin: #{@info[:plugin]}"
            end
            @info = nil
        rescue Object => boom
            Logger.warn("Received a plugin load response and not expected: #{boom}")
        ensure
            @lock.unlock
        end
    end

    def respond_unload(m)
        begin
            raise "Not waiting for a reply" if @info.nil?
            if(m.success)
                information @info[:reply], "Successfully unloaded plugin: #{@info[:plugin]}"
            else
                error @info[:reply], "Failed to unload plugin: #{@info[:plugin]}"
            end
            @info = nil
        rescue Object => boom
            Logger.warn("Received a plugin unload response and not expected: #{boom}")
        ensure
            @lock.unlock
        end
    end
    
    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Unload the given plugin
    def unload_plugin(message, params)
        @lock.lock
        @pipeline << Messages::Internal::PluginUnloadRequest.new(self, params[:plugin].to_sym)
        @info = {:reply = message.replyto, :plugin => params[:plugin]}
        information message.replyto, "Attempting to unload plugin: #{params[:plugin]}"
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: matching signature params
    # Reloads plugins
    def reload_plugin(message, params)
        if(params[:plugin])
            @pipeline << Messages::Internal::PluginReload.new(params[:plugin])
            information message.replyto, "Reloading #{params[:plugin]}"
        else
            @pipeline << Messages::Internal::PluginReload.new
            information message.replyto, 'Full plugin reload requested'
        end
    end
end