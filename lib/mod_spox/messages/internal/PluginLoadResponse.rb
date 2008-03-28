module ModSpox
    module Messages
        module Internal
            class PluginLoadResponse < Response
                # success of loading
                attr_reader :success
                # successful:: load was successful
                # Notifies requesting object if load was successful
                def initialize(object, successful)
                    super(object)
                    @success = successful
                end
            end
        end
    end
end