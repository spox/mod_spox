module ModSpox

    class Pipeline < Pool
    
        # procs:: number of threads running in Pool
        # Create a new Pipeline
        def initialize(procs=3)
            super(procs)
            @messageq = Queue.new
            Logger.log("Created queue #{@messageq} in pipeline", 10)
            @hooks = Hash.new
            @plugins = Hash.new
            populate_triggers
            populate_signatures
            hook(self, :populate_triggers, :Internal_TriggersUpdate)
            hook(self, :populate_signatures, :Internal_SignaturesUpdate)
            start_pool
        end
        
        # message:: Message to send down pipeline
        # Queues a message to send down pipeline
        def <<(message)
            Logger.log("Message added to pipeline queue: #{message}", 5)
            @messageq << message
        end
        
        # plugin:: Plugin to hook to pipeline
        # Hooks a plugin into the pipeline so it can be called
        # directly when it matches a trigger
        def hook_plugin(plugin)
            Logger.log("Plugin #{plugin.name} hooking into pipeline", 10)
            @plugins[plugin.name.to_sym] = plugin
        end
        
        # plugin:: Plugin to unhook from pipeline
        # Unhooks a plugin from the pipeline (This does not unhook
        # it from the standard hooks)
        def unhook_plugin(plugin)
            Logger.log("Plugin #{plugin.name} unhooking from plugin", 10)
            @plugins.delete(plugin.name.to_sym)
            @hooks.each_pair do |type, things|
                things.delete(plugin.name.to_sym) if things.has_key?(plugin.name.to_sym)
            end
        end
        
        # plugin:: Plugin to hook to pipeline
        # method:: Plugin method pipeline should call to process message
        # type:: Type of message the plugin wants to process
        # Hooks a plugin into the pipeline for a specific type of message
        def hook(object, method, type)
            Logger.log("Object #{object.class.to_s} hooking into messages of type: #{type}", 10)
            type = type.gsub(/::/, '_').to_sym unless type.is_a?(Symbol)
            method = method.to_sym unless method.is_a?(Symbol)
            name = object.class.to_s.gsub(/^.+:/, '')
            @hooks[type] = Hash.new unless @hooks.has_key?(type)
            @hooks[type][name.to_sym] = Array.new unless @hooks[type][name.to_sym].is_a?(Array)
            @hooks[type][name.to_sym] << {:object => object, :method => method} 
        end
        
        # plugin:: Plugin to unhook from pipeline
        # type:: Type of message the plugin no longer wants to process
        # This will remove the hook a plugin has for a specific message type
        def unhook(object, method, type)
            Logger.log("Object #{object.class.to_s} unhooking from messages of type: #{type}", 10)
            type = type.gsub(/::/, '_').to_sym unless type.is_a?(Symbol)
            name = object.class.gsub(/^.+:/, '').to_sym
            raise Exception::InvalidValue.new("Unknown hook type given: #{type.to_s}") unless @hooks.has_key?(type)
            raise Exception::InvalidValue.new("Unknown object hooked: #{name.to_s}") unless @hooks[type].has_key?(name)
            @hooks[type][name].each{|hook|
                @hooks[type][name].delete(hook) if hook[:method] == method
            }
            @hooks[type].delete(name) if @hooks[type][name].empty
            @hooks.delete(type) if @hooks[type].empty?
        end
        
        # Clears all hooks from the pipeline (Commonly used when reloading plugins)
        def clear
            Logger.log("All hooks have been cleared from pipeline", 10)
            @hooks.clear
            @plugins.clear
        end
        
        def populate_triggers(m=nil)
            @triggers = []
            Models::Trigger.filter(:active => true).each{|t|@triggers << t.trigger}
        end
        
        def populate_signatures(m=nil)
            @signatures = []
            Models::Signature.all.each{|s|@signatures << s}
        end
        
        private
        
        # Processes messages
        def processor
            begin
                message = @messageq.pop
                Logger.log("Pipeline is processing a message: #{message}", 10)
                parse(message)
                type = message.class.to_s.gsub(/^ModSpox::Messages::/, '').gsub(/::/, '_').to_sym
                mod = type.to_s.gsub(/_.+$/, '').to_sym
                Logger.log("Pipeline determines that #{message} is of type: #{type}", 10)
                [type, mod, :all].each{|type|
                    if(@hooks.has_key?(type))
                        @hooks[type].each_value{|objects| 
                            objects.each{|v| v[:object].send(v[:method].to_s, message) } 
                        }
                    end
                } 
            rescue Object => boom
                Logger.log("Pipeline encountered an exception while processing a message: #{boom}\n#{boom.backtrace.join("\n")}", 10)
            end
        end
        
        # message:: Message to parse
        # This will parse a message to see if it matches any valid
        # trigger signatures. If matches are found, they will be sent
        # to the proper plugin for processing 
        def parse(message)
            return unless message.kind_of?(Messages::Incoming::Privmsg) || message.kind_of?(Messages::Incoming::Notice)
            trigger = nil
            @triggers.each{|t| trigger = t if message.message =~ /^#{t}/}
            if(!trigger.nil? || message.addressed?)
                Logger.log("Message has matched against a known trigger", 15)
                @signatures.each{|sig|
                    Logger.log("Matching against: #{trigger}#{sig.signature}")
                    res = message.message.scan(/^#{trigger}#{sig.signature}$/)
                    if(res.size > 0)
                        next unless message.source.auth_groups.include?(sig.group) || sig.group.nil?
                        params = Hash.new
                        sig.params.size.times do |i|
                            params[sig.params[i - 1].to_sym] = res[0][i]
                            Logger.log("Signature params: #{sig.params[i - 1].to_sym} = #{res[0][i]}")
                        end
                        if(@plugins.has_key?(sig.plugin.to_sym))
                            @plugins[sig.plugin.to_sym].send(sig.values[:method], message, params)
                        end
                    end
                }
            else
                Logger.log("Message failed to match any known trigger", 15)
            end
        end
    
    end

end