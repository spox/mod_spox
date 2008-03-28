module ModSpox
    module Messages
        module Internal
            class PluginLoadRequest < Request
                # path to plugin file
                attr_reader :path
                # file name for plugin
                attr_reader :name
                # object:: object requesting the load
                # path:: path to plugin file to be loaded
                # Loads a plugin located at the given path
                def initialize(object, path, name=nil)
                    super(object)
                    @path = path
                    @name = name
                end
            end
        end
    end
end