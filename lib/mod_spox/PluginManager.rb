require 'splib'
Splib.load :CodeReloader, :Constants

module ModSpox
    # Manages plugins for mod_spox
    class PluginManager
        # Create a new plugin manager
        # :nodoc:
        # {:PluginName => {:module => Module(containing constants), :plugin => Plugin instance}}
        def initialize
            @plugins = {}
        end
    end

    def load_plugin
    end

    def unload_plugin
    end

    def reload_plugins
    end

    def find_plugins
    end

    def find_gem_plugins

    end

    def find_local_plugins
        if(File.exists?(ModSpox.config_dir) && File.directory?(ModSpox.config_dir))
            Dir.glob("#{ModSpox.config_dir}/")
        end
    end
end
