require 'mod_spox/messages/internal/Request'
module ModSpox
    module Messages
        module Internal
            class PluginLoadRequest < Request
                # name of plugin to load
                attr_reader :name
                # object:: object requesting the load
                # name:: name of plugin to load
                # Loads a plugin 
                def initialize(object, name=nil)
                    super(object)
                    @name = name
                end
            end
        end
    end
end