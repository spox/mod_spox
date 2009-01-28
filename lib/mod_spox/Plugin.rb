['mod_spox/Pipeline',
 'mod_spox/Logger',
 'mod_spox/Exceptions'].each{|f|require f}
module ModSpox
    class Plugin
        include Models
        def initialize(args)
            @pipeline = args[:pipeline]
            @plugin_module = args[:plugin_module]
            raise Exceptions::BotException.new('Plugin creation failed to supply message pipeline') unless @pipeline.is_a?(Pipeline)
            @pipeline.hook_plugin(self)
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
                raise Exception.new("Fatal Error: I don't know who I am.")
            end
        end

        # Returns constant given from plugin module. Raises ModSpox::Exceptions::InvalidType
        # exception if constant is not found within the module
        # Note: Use _ for depth (ie: Foo::Bar::Fee if Fee is wanted give: :Foo_Bar_Fee)
        def plugin_const(const)
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
        # Optional args: :group, :req, and :params
        def add_sig(args)
            raise ModSpox::Exceptions::InvalidType.new('You must provide a hash for creating new signatures') unless args.is_a?(Hash)
            sig = Signature.find_or_create(:signature => args[:sig], :plugin => name, :method => args[:method].to_s)
            sig.description = args[:desc] if args.has_key?(:desc)
            sig.group_id = args[:group].pk if args.has_key?(:group)
            sig.requirement = args[:req] if args.has_key?(:req)
            sig.params = args[:params] if args.has_key?(:params)
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