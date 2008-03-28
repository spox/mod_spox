module ModSpox
    module Messages
        module Internal
            class PluginModuleRequest < Request
                # object:: object requesting the load
                # Requests the plugin module
                def initialize(object)
                    super(object)
                end
            end
        end
    end
end