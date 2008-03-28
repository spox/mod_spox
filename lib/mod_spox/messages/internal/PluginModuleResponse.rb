module ModSpox
    module Messages
        module Internal
            class PluginModuleResponse < Response
                # plugins module
                attr_reader :module
                # plugin:: Plugin to send to requester
                # Sends the plugins module to the requester
                def initialize(object, mod)
                    super(object)
                    @module = mod
                end

            end
        end
    end
end