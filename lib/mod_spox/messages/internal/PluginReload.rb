module ModSpox
    module Messages
        module Internal
            # Sends message to reload plugin. If new and stale
            # attributes are set, only that plugin will be reloaded
            class PluginReload
                # Path to new plugin to load
                attr_reader :fresh
                # Path to stale plugin to remove
                attr_reader :stale
                def initialize(fresh=nil, stale=nil)
                    @fresh = fresh
                    @stale = stale
                end
            end
        end
    end
end