['mod_spox/Pipeline',
 'mod_spox/Logger',
 'mod_spox/Exceptions'].each{|f|require f}
module ModSpox
    class Plugin
        def initialize(args)
            @pipeline = args[:pipeline]
            @plugin_module = args[:plugin_module]
            raise Exceptions::BotException.new('Plugin creation failed to supply message pipeline') unless @pipeline.is_a?(Pipeline)
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

    end
end