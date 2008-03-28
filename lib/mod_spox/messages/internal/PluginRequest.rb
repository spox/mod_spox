module ModSpox
    module Messages
        module Internal
            class PluginRequest  < Request
                # plugin requested
                attr_reader :plugin
                # object:: object requesting
                # name:: Name of plugin
                # Request plugin from bot
                def initialize(object, name)
                    super(object)
                    @name = name.is_a?(Symbol) ? name : name.to_sym
                end
            end
        end
    end
end