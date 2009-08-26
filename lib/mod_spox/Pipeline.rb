['mod_spox/models/Models.rb',
 'mod_spox/Logger',
 'mod_spox/Exceptions',
 'mod_spox/messages/incoming/Privmsg',
 'mod_spox/messages/incoming/Notice',
 'mod_spox/FilterManager'].each{|f|require f}
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
            hook(self, :populate_triggers, ModSpox::Messages::Internal::TriggersUpdate)
            hook(self, :populate_signatures, ModSpox::Messages::Internal::SignaturesUpdate)
            @filters = FilterManager.new(self)
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
            type = Helpers.find_const(type)
            method = method.to_sym unless method.is_a?(Symbol)
            name = object.class
            @hooks[type] ||= Hash.new
            @hooks[type][name] ||= Array.new
            @hooks[type][name] << {:object => object, :method => method}
        end

        # plugin:: Plugin to unhook from pipeline
        # type:: Type of message the plugin no longer wants to process
        # This will remove the hook a plugin has for a specific message type
        def unhook(object, method, type)
            Logger.info("Object #{object.class.to_s} unhooking from messages of type: #{type}")
            type = Helpers.find_const(type)
            name = object.class
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
                    if(c =~ /^[A-Za-z]$/)
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
            @filters.apply_filters(message)
            return if message.nil?
            @hooks.keys.each do |type|
                next unless Helpers.type_of?(message, type, true)
                @hooks[type].each_value do |objects|
                    objects.each do |v|
                        @pool.process do
                            begin
                                v[:object].send(v[:method], message)
                            rescue Object => boom
                                if(boom.class.to_s == 'SQLite3::BusyException')
                                    Database.reset_connections
                                end
                                raise boom
                            end
                        end
                    end
                end
            end
            parse(message)
        end

        # message:: Message to parse
        # This will parse a message to see if it matches any valid
        # trigger signatures. If matches are found, they will be sent
        # to the proper plugin for processing
        def parse(message)
            return unless message.is_a?(Messages::Incoming::Privmsg) || message.is_a?(Messages::Incoming::Notice)
            trigger = nil
            @triggers.each{|t| trigger = t if message.message[0..t.size-1] == t}
            unless(trigger.nil? && !message.addressed?)
                return if trigger && message.message.length == trigger.length
                Logger.info('Messages has matched a known trigger')
                # okay, so now that we know we are being asked to do something, lets find
                # a signature that might match. Signatures are sorted by first character
                # so once we have that we can get rolling
                c = (message.addressed? && trigger.nil?) ? message.message[0].chr : message.message[trigger.length].chr
                case c
                    when /[A-Za-z]/
                        type = c.to_sym
                    when /\d/
                        type = :digit
                    else
                        type = :other
                end
                sig_check = @signatures[type] ? @signatures[type] : []
                sig_check += @signatures[:other] if @signatures[:other] && type != :other # others are always checked because they are fickle shells of what they once were
                sig_check.each do |sig|
                    Logger.info("Matching against: #{trigger}#{sig.signature}")
                    esc_trig = trigger.nil? ? '' : Regexp.escape(trigger)
                    result = message.message.scan(/^#{esc_trig}#{sig.signature}$/)
                    if(result.size > 0 && @plugins[sig.plugin.to_sym])
                        next unless allowed?(message, sig)
                        params = Hash.new
                        # symbolize up the parameters for symbolic symbolism
                        sig.params.size.times do |i|
                            params[sig.params[i].to_sym] = result[0][i]
                            Logger.info("Signature params: #{sig.params[i]} = #{result[0][i]}")
                        end
                        # throw it in the pool for processing
                        @pool.process do
                            begin
                                @plugins[sig.plugin.to_sym].send(sig.values[:method], message, params)
                            rescue Object => boom
                                if(boom.class.to_s == 'SQLite3::BusyException')
                                    Database.reset_connections
                                end
                                raise boom
                            end
                        end
                    end
                end
            else
                Logger.info('Message failed to match any known trigger')
            end
        end

        # message:: ModSpox::Messages::Incoming
        # sig:: ModSpox::Models::Signature
        # Check if the given message is allowed to be processed
        def allowed?(message, sig)
            return false if sig.requirement == 'private' && message.is_public?
            return false if sig.requirement == 'public' && message.is_private?
            return (message.source.in_group?(sig.group) || message.source.in_group?(@admin) || sig.group.nil?)
        end

    end

end