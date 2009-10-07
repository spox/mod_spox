module ModSpox
    module Messages
        module Internal
            # Sends message to reload plugin. If new and stale
            # attributes are set, only that plugin will be reloaded
            class PluginReload
                # name of plugin to reload
                attr_reader :name
                def initialize(name=nil)
                    @name = name
                end
            end
        end
    end
end