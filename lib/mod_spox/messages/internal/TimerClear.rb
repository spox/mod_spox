module ModSpox
    module Messages
        module Internal
            class TimerClear
                attr_reader :plugin
                def initialize(plugin=nil)
                    if(plugin.nil?)
                        @plugin = nil
                    else
                        @plugin = plugin.is_a?(ModSpox::Plugin) ? plugin.name.to_sym : plugin.to_sym
                    end
                end
            end
        end
    end
end