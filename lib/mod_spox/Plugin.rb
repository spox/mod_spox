module ModSpox
    class Plugin
        def initialize(pipeline)
            @pipeline = pipeline
            @pipeline.hook_plugin(self)
        end
        
        # Called before the object is destroyed by the ModSpox::PluginManager
        def destroy
            Logger.log("Destroy method for plugin #{name} has not been defined.", 15)
        end
        
        # Returns the name of the class
        def name
            self.class.name.to_s.gsub(/^.+:/, '')
        end
    end
end