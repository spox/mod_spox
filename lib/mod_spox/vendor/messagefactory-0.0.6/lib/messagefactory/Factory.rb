require 'splib'
Splib.load :Monitor

require 'messagefactory/Handler'

module MessageFactory
    class Factory
        # Create a new Factory
        def initialize
            @handlers = {}
            @lock = Splib::Monitor.new
        end

        # s:: string from server
        # Determine type of message
        def type(s)
            s = s.dup
            t = nil
            begin
                if(s.slice(0,1) == ':')
                    s.slice!(0..s.index(' '))
                    t = s.slice!(0..s.index(' ')-1)
                else
                    t = s.slice(0..s.index(' ')-1)
                end
                t.strip!
            rescue => e
                puts e
                raise 'Failed to determine message type'
            end
            t.to_sym
        end

        # string:: String from IRC server to process
        # Process the given string and return parsed
        # message or nil
        def process(string, do_require=true)
            s = nil
            mtype = type(string)
            if(@handlers[mtype])
                s = @handlers[mtype].process(string)
            else
                if(do_require)
                    begin
                        require "messagefactory/handlers/#{mtype}"
                        load_handlers
                        s = process(string, false)
                    rescue LoadError
                        s = mk_unknown(string)
                    end
                else
                    s = mk_unknown(string)
                end
            end
            s
        end

        private

        def mk_unknown(string)
            s = Message.new
            s.direction = :incoming
            s.received = Time.now
            s.raw = string.dup
            s.type = :UNKNOWN
            s
        end

        def load_handlers
            @lock.synchronize do
                loaded = @handlers.values.map{|x|x.class}
                MessageFactory::Handlers.constants.each do |cons|
                    klas = MessageFactory::Handlers.const_get(cons)
                    if(klas.is_a?(Class) && klas < MessageFactory::Handlers::Handler && !loaded.include?(klas))
                        handler = klas.new
                        if(handler.types_process.is_a?(Array))
                            handler.types_process.each do |t|
                                @handlers[t] = handler
                            end
                        else
                            @handlers[handler.types_process] = handler
                        end
                    end
                end
            end
        end

    end
end