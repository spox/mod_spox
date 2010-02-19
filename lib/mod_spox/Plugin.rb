['mod_spox/Pipeline',
 'mod_spox/Logger',
 'mod_spox/Exceptions',
 'mod_spox/messages/outgoing/Privmsg'].each{|f|require f}
module ModSpox
    class Plugin
        include Models
        def initialize(args)
            @pipeline = args[:pipeline]
            @plugin_module = nil
            raise Exceptions::BotException.new('Plugin creation failed to supply message pipeline') unless @pipeline.is_a?(Pipeline)
            @pipeline.hook(self, :set_module, ModSpox::Messages::Internal::PluginModuleResponse)
            @pipeline.hook_plugin(self)
        end

        # m:: Modspox::Messages::Internal::PluginModuleReponse
        # Set the plugin module
        def set_module(m)
            @plugin_module = m.module
        end

        # Called before the object is destroyed by the ModSpox::PluginManager
        def destroy
            Logger.info("Destroy method for plugin #{name} has not been defined.")
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

        # Returns the nick model of the bot
        def me
            nick = Models::Nick.filter(:botnick => true).first
            if(nick)
                return nick
            else
                raise Exception.new("I don't know who I am. Hold me, I'm scared!")
            end
        end

        # Returns constant given from plugin module. Raises ModSpox::Exceptions::InvalidType
        # exception if constant is not found within the module
        # Note: Use _ for depth (ie: Foo::Bar::Fee if Fee is wanted give: :Foo_Bar_Fee)
        # Second Note: This method will not return a valid result during initialization
        def plugin_const(const)
            return nil if @plugin_module.nil?
            klass = @plugin_module
            begin
                const.to_s.split('_').each do |part|
                    klass = klass.const_get(part.to_sym)
                end
            rescue NameError => boom
                raise ModSpox::Exceptions::InvalidType.new("Requested constant has not been defined within the plugins module (#{const}): #{boom}")
            end
            if(klass.nil?)
                raise ModSpox::Exceptions::InvalidType.new("Requested constant has not been defined within the plugins module (#{const})")
            else
                return klass
            end
        end
        
        # Adds a new signature for the given plugin
        # Required args: :sig and :method
        # Optional args: :group, :req, :desc, and :params
        def add_sig(args)
            raise ModSpox::Exceptions::InvalidType.new('You must provide a hash for creating new signatures') unless args.is_a?(Hash)
            args[:params] = nil unless args[:params]
            sig = Signature.find_or_create(:signature => args[:sig], :plugin => name, :method => args[:method].to_s,
                                            :params => args[:params], :group_id => args[:group].nil? ? nil : args[:group].pk)
            sig.description = args[:desc] if args.has_key?(:desc)
            sig.requirement = args[:req] if args.has_key?(:req)
            sig.save
        end
        
        # to:: Where message is going
        # message:: message
        # Send an information message to target
        def information(to, message)
            reply to, "\2#{name} (info):\2 #{message}"
        end
        
        # to:: Where message is going
        # message:: message
        # Send an warning message to target
        def warning(to, message)
            reply to, "\2#{name} (warn):\2 #{message}"
        end
        
        # to:: Where message is going
        # message:: message
        # Send an error message to target
        def error(to, message)
            reply to, "\2#{name} (error):\2 #{message}"
        end

    end
end