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
            @available = {}
            RFC.each_pair{|k,v| @avaliable[v[:value]] = v[:handlers]}
            @sync = [:RPL_MOTDSTART, :RPL_MOTD, :RPL_ENDOFMOTD, :RPL_WHOREPLY, :RPL_ENDOFWHO,
                     :RPL_NAMREPLY, :RPL_ENDOFNAMES, :RPL_WHOISUSER, :RPL_WHOISSERVER, :RPL_WHOISOPERATOR,
                     :RPL_WHOISIDLE, :RPL_WHOISCHANNELS, :RPL_WHOISIDENTIFIED, :RPL_ENDOFWHOIS].map{|s| RFC[s][:value]}
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
                if(s[0].chr == ':')
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

        # message:: server message
        # Parses the server message and passes it to the proper handler
        def parse_message(message)
            Logger.info("Processing message: #{message}")
            loaded = false
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
                    raise Exceptions::HanlderNotFound.new(key)
                end
            rescue Exceptions::HandlerNotFound => boom
                unless(loaded)
                    if(@available[boom.message_type] && @available[boom.message_type].has_key?(:handlers))
                        @avalable[boom.message_type].each do|f|
                            require "mod_spox/handlers/#{f}"
                            klass = ModSpox::Handlers.const_get(f)
                            if(klass.nil?)
                                Logger.error("File name does not seem to match class name. Now what? #{boom}")
                            else
                                klass.new(self)
                            end
                        end
                        Logger.info("Loaded handler for message type: #{boom.message_type}. Reprocessing message")
                        loaded = true
                        retry
                    end
                end
                raise boom
            rescue Object => boom
                if(boom.class.to_s == 'SQLite3::BusyException' || boom.class.to_s == 'PGError')
                    Database.reset_connections
                    retry
                else
                    Logger.warn("Failed to parse message from server: #{boom}\n#{boom.backtrace.join("\n")}")
                end
            end
        end

    end

end