['mod_spox/handlers/Handler',
 'mod_spox/Logger',
 'mod_spox/Pipeline',
 'mod_spox/Pool'].each{|f|require f}

module ModSpox

    class MessageFactory < Pool
    
        # pipeline:: Message pipeline
        # Create a new MessageFactory
        def initialize(pipeline)
            super()
            @pipeline = pipeline
            @handlers = Hash.new
            Logger.log("Created new factory queue: #{@queue}", 15)
            build_handlers
            start_pool
        end
        
        # string:: server message to be parsed
        # Parses messages from server. This is placed in a queue to
        # be processed thus there is now wait for processing to be
        # completed.
        def <<(string)
            @queue << string
        end
        
        # Builds the message handlers. This will load all Messages and Handlers
        # found in the lib directory and then initialize all the Handlers
        def build_handlers
            # load our handlers in first
            # note: the handlers add themselves to the @handlers hash
            # during initialization
            Handlers.constants.each{|name|
                klass = Handlers.const_get(name)
                if(klass < Handlers::Handler)
                    Logger.log("Building handler: #{name}")
                    begin
                        klass.new(@handlers)
                    rescue Object => boom
                        Logger.log("ERROR: Failed to build handler: #{name} -> #{boom}")
                    end
                end
            }
            Logger.log("Handlers now available:", 15)
            @handlers.each_pair{|k,v| Logger.log("#{k} -> #{v}", 15)}
        end
        
        # message:: server message
        # Parses the server message and passes it to the proper handler
        def parse_message(message)
            Logger.log("Processing message: #{message}", 15)
            begin
                if(message =~ /^:\S+ (\S+)/ || message =~ /^([A-Za-z0-9]+)\s/)
                    key = $1
                    key = key.to_sym unless key[0].chr =~ /\d/
                    if(@handlers.has_key?(key))
                        Logger.log("Message of type #{key} is now being handled by #{@handlers[key]}", 10)
                        message = @handlers[key].process(message)
                        @pipeline << message unless message.nil?
                    end
                end
            rescue Object => boom
                Logger.log("Failed to parse message from server: #{boom}\n#{boom.backtrace.join("\n")}")
            end
        end
        
        private
        
        def processor
            parse_message(@queue.pop)
        end
    
    end

end