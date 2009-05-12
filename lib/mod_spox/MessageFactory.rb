['mod_spox/handlers/Handler',
 'mod_spox/Logger',
 'mod_spox/Pipeline'].each{|f|require f}

module ModSpox

    class MessageFactory

        # access to handlers. (only really needed for testing)
        attr_reader :handlers

        # pipeline:: Message pipeline
        # Create a new MessageFactory
        def initialize(pipeline, pool)
            @pipeline = pipeline
            @pool = pool
            @sync_pool = ActionPool::Pool.new(1, 1, nil, 2, Logger.raw)
            @handlers = Hash.new
            build_handlers
            @sync = [RPL_MOTDSTART, RPL_MOTD, RPL_ENDOFMOTD, RPL_WHOREPLY, RPL_ENDOFWHO,
                     RPL_NAMREPLY, RPL_ENDOFNAMES, RPL_WHOISUSER, RPL_WHOISSERVER, RPL_WHOISOPERATOR,
                     RPL_WHOISIDLE, RPL_WHOISCHANNELS, RPL_WHOISIDENTIFIED, RPL_ENDOFWHOIS]
        end

        # string:: server message to be parsed
        # Parses messages from server. This is placed in a queue to
        # be processed thus there is now wait for processing to be
        # completed.
        def <<(string)
            @pool.process{ parse_message(string) }
        end

        # s:: string from server
        # determine type of message from server
        def find_key(s)
            s = s.dup
            begin
                key = nil
                if(s[0] == ':')
                    s.slice!(0..s.index(' '))
                    key = s.slice!(0..s.index(' ')-1)
                else
                    key = s.slice(0..s.index(' ')-1)
                end
                key.strip!
                key = key.to_sym if key.to_i == 0
                return key
            rescue Object
                Logger.info("Failed to find key for message: #{s}")
                raise Exceptions::UnknownKey.new
            end
        end

        private

        # Builds the message handlers. This will load all Messages and Handlers
        # found in the lib directory and then initialize all the Handlers
        def build_handlers
            # load our handlers in first
            # note: the handlers add themselves to the @handlers hash
            # during initialization
            Handlers.constants.each{|name|
                klass = Handlers.const_get(name)
                if(klass < Handlers::Handler)
                    Logger.info("Building handler: #{name}")
                    begin
                        klass.new(@handlers)
                    rescue Object => boom
                        Logger.warn("ERROR: Failed to build handler: #{name} -> #{boom}")
                    end
                end
            }
            Logger.info("Handlers now available:")
            @handlers.each_pair{|k,v| Logger.info("#{k} -> #{v}")}
        end

        # message:: server message
        # Parses the server message and passes it to the proper handler
        def parse_message(message)
            Logger.info("Processing message: #{message}")
            begin
                key = find_key(message)
                if(@handlers.has_key?(key))
                    Logger.info("Message of type #{key} is now being handled by #{@handlers[key]}")
                    if(@sync.include?(key))
                        Logger.info("Message of type #{key} requires synchronized processing")
                        @sync_pool.process do
                            message = @handlers[key].process(message)
                            @pipeline << message unless message.nil?
                        end
                    else
                        @pool.process do
                            message = @handlers[key].process(message)
                            @pipeline << message unless message.nil?
                        end
                    end
                else
                    Logger.error("No handler was found to process message of type: #{key} Message: #{message}")
                end
            rescue Object => boom
                Logger.warn("Failed to parse message from server: #{boom}\n#{boom.backtrace.join("\n")}")
            end
        end

    end

end