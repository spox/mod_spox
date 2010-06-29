require 'ostruct'

unless(OpenStruct.new.type.nil?)
    class OpenStruct
        def type
            @table[:type]
        end
    end
end

module MessageFactory
    class Message < OpenStruct
    end
end

module MessageFactory
module Handlers
    class Handler

        # Returns symbol or array of symbols of allowed message types
        def types_process
            raise NotImplementedError.new
        end

        # data:: string of data
        # Process string and create proper message
        def process(data)
            raise NotImplementedError.new
        end

        protected

        # orig:: Original message string
        # Helper to generate the message struct
        def mk_struct(orig=nil)
            m = Message.new
            m.direction = :incoming
            m.received = Time.now
            m.raw = orig.dup
            m
        end
    end
end
end
