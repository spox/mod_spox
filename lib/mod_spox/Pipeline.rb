['mod_spox/models/Models.rb',
 'mod_spox/Logger',
 'mod_spox/Exceptions'].each{|f|require f}
module ModSpox

    class Pipeline

        # Create a new Pipeline
        def initialize(pool)
            @pool = pool
            @hooks = Hash.new
            @plugins = Hash.new
            @admin = Models::Group.filter(:name => 'admin').first
            @populate_lock = Mutex.new
            populate_triggers
            populate_signatures
            hook(self, :populate_triggers, :Internal_TriggersUpdate)
            hook(self, :populate_signatures, :Internal_SignaturesUpdate)
        end

        # message:: Message to send down pipeline
        # Queues a message to send down pipeline
        def <<(message)
            Logger.info("Message added to pipeline queue: #{message}")
            message_processor(message)
        end

        # plugin:: Plugin to hook to pipeline
        # Hooks a plugin into the pipeline so it can be called
        # directly when it matches a trigger
        def hook_plugin(plugin)
            Logger.info("Plugin #{plugin.name} hooking into pipeline")
            @plugins[plugin.name.to_sym] = plugin
        end

        # plugin:: Plugin to unhook from pipeline
        # Unhooks a plugin from the pipeline (This does not unhook
        # it from the standard hooks)
        def unhook_plugin(plugin)
            Logger.info("Plugin #{plugin.name} unhooking from pipeline")
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
            Logger.info("Object #{object.class.to_s} hooking into messages of type: #{type}")
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
            Logger.info("Object #{object.class.to_s} unhooking from messages of type: #{type}")
            type = type.gsub(/::/, '_').to_sym unless type.is_a?(Symbol)
            name = object.class.to_s.gsub(/^.+:/, '').to_sym
            raise Exceptions::InvalidValue.new("Unknown hook type given: #{type.to_s}") unless @hooks.has_key?(type)
            raise Exceptions::InvalidValue.new("Unknown object hooked: #{name.to_s}") unless @hooks[type].has_key?(name)
            @hooks[type][name].each{|hook|
                @hooks[type][name].delete(hook) if hook[:method] == method
            }
            @hooks[type].delete(name) if @hooks[type][name].empty
            @hooks.delete(type) if @hooks[type].empty?
        end

        # Clears all hooks from the pipeline (Commonly used when reloading plugins)
        def clear
            Logger.info("All hooks have been cleared from pipeline")
            @hooks.clear
            @plugins.clear
        end

        # Repopulate the active trigger list
        def populate_triggers(m=nil)
            @populate_lock.synchronize do
                @triggers = []
                Models::Trigger.filter(:active => true).each{|t|@triggers << t.trigger}
            end
        end

        # Repopulate the active signatures list
        def populate_signatures(m=nil)
            @populate_lock.synchronize do
                @signatures = {}
                a = Models::Signature.filter(:enabled => false)
                Logger.warn("Killing #{a.count} signatures")
                a.destroy
                Models::Signature.all.each do |s|
                    c = s.signature[0].chr.downcase
                    if(c =~ /^[a-z]$/)
                        type = c.to_sym
                    elsif(c =~ /^[0-9]$/)
                        type = :digit
                    else
                        type = :other
                    end
                    @signatures[type] = [] unless @signatures[type]
                    unless @signatures.include?(s)
                        @signatures[type] << s
                    end
                end
            end
        end

        private

        # Processes messages
        def message_processor(message)
            begin
                Logger.info("Pipeline is processing a message: #{message}")
                parse(message)
                type = message.class.to_s.gsub(/^(ModSpox::Messages::|#<.+?>::)/, '').gsub('::', '_').to_sym
                mod = type.to_s.gsub(/_.+$/, '').to_sym
                Logger.info("Pipeline determines that #{message} is of type: #{type}")
                [type, mod, :all].each do |type|
                    if(@hooks.has_key?(type))
                        @hooks[type].each_value do |objects|
                            begin
                                objects.each do |v|
                                    @pool.process{ v[:object].send(v[:method].to_s, message) }
                                end
                            rescue Object => boom
                                Logger.warn("Plugin threw exception while attempting to process message: #{boom}\n#{boom.backtrace.join("\n")}")
                            end
                        end
                    end
                end
            rescue Object => boom
                Logger.warn("Pipeline encountered an exception while processing a message: #{boom}\n#{boom.backtrace.join("\n")}")
            end
        end

        # message:: Message to parse
        # This will parse a message to see if it matches any valid
        # trigger signatures. If matches are found, they will be sent
        # to the proper plugin for processing
        def parse(message)
            return unless message.kind_of?(Messages::Incoming::Privmsg) || message.kind_of?(Messages::Incoming::Notice)
            trigger = nil
            @triggers.each{|t| trigger = t if message.message[0..t.size-1] == t}
            if(!trigger.nil? || message.addressed?)
                return if !trigger.nil? && message.message.length == trigger.length
                Logger.info("Message has matched against a known trigger")
                c = (message.addressed? && trigger.nil?) ? message.message[0].chr.downcase : message.message[trigger.length].chr.downcase
                if(c =~ /^[a-z]$/)
                    type = c.to_sym
                elsif(c =~ /^[0-9]$/)
                    type = :digit
                else
                    type = :other
                end
                sig_check = @signatures.has_key?(type) ? @signatures[type] : []
                sig_check = sig_check + @signatures[:other] if type != :other && @signatures.has_key?(:other)
                sig_check.each do |sig|
                    Logger.info("Matching against: #{trigger}#{sig.signature}")
                    esc_trig = trigger.nil? ? '' : Regexp.escape(trigger)
                    res = message.message.scan(/^#{esc_trig}#{sig.signature}$/)
                    if(res.size > 0)
                        next unless message.source.in_group?(sig.group) || message.source.in_group?(@admin) || sig.group.nil?
                        next if sig.requirement == 'private' && message.is_public?
                        next if sig.requirement == 'public' && message.is_private?
                        params = Hash.new
                        sig.params.size.times do |i|
                            params[sig.params[i].to_sym] = res[0][i]
                            Logger.info("Signature params: #{sig.params[i].to_sym} = #{res[0][i]}")
                        end
                        if(@plugins.has_key?(sig.plugin.to_sym))
                            begin
                                @pool.process{ @plugins[sig.plugin.to_sym].send(sig.values[:method], message, params) }
                            rescue Object => boom
                                Logger.warn("Plugin threw exception while attempting to process message: #{boom}\n#{boom.backtrace.join("\n")}")
                            end
                        end
                    end
                end
            else
                Logger.info("Message failed to match any known trigger")
            end
        end

    end

end