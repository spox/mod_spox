require 'mod_spox/messages/internal/Request'
module ModSpox
    module Messages
        module Internal
            class PluginUnloadRequest < Request
                # name of plugin to unload
                attr_reader :name
                # object:: object requesting the unload
                # name:: name of plugin to unload
                # Unloads a plugin
                def initialize(object, name=nil)
                    super(object)
                    @name = name
                end
            end
        end
    end
end