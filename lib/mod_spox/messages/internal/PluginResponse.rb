require 'mod_spox/messages/internal/Response'
module ModSpox
    module Messages
        module Internal
            class PluginResponse < Response
                # plugin object
                attr_reader :plugin
                # plugin:: Plugin to send to requester
                # Sends a plugin to requesting object
                def initialize(object, plugin)
                    super(object)
                    @plugin = plugin
                end
                
                def found?
                    return !@plugin.nil?
                end
            end
        end
    end
end