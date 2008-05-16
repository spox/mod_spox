module ModSpox
    # Holder for plugin
    class PluginHolder
        # Create a new holder with a plugin
        def initialize(plugin)
            @plugin = plugin
            @lock = Mutex.new
        end
        # plugin:: Plugin to set into this holder
        def set_plugin(plugin)
            @lock.synchronize do
                @plugin = plugin
            end
        end
        # Returns the plugin this holder contains
        def plugin
            @lock.synchronize do
                return @plugin
            end
        end
    end
end