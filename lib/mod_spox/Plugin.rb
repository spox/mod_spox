module ModSpox
    class Plugin
        def initialize(pipeline)
            raise Exceptions::BotException.new('Plugin creation failed to supply message pipeline') unless pipeline.is_a?(Pipeline)
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
        
        # target:: target for message
        # message:: string message
        # This is a helper method that will send an outgoing Privmsg
        # to the given target
        def reply(target, message)
            @pipeline << Messages::Outgoing::Privmsg.new(target, message)
        end
    end
end