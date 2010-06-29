module MessageFactory
module Handlers
    class Kick < Handler
        def types_process
            :KICK
        end
        # string:: string to process
        # Create a new Kick message
        # OpenStruct will contain:
        # #type #direction #raw #received #source #target #channel #message
        # :nodoc: :spax!~spox@host KICK #m spox :foo
        def process(string)
            string = string.dup
            orig = string.dup
            m = nil
            begin
                m = mk_struct(string)
                m.type = :kick
                string.slice!(0)
                m.source = string.slice!(0, string.index(' '))
                string.slice!(0)
                raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :KICK
                string.slice!(0)
                m.channel = string.slice!(0, string.index(' '))
                string.slice!(0)
                m.target = string.slice!(0, string.index(' '))
                string.slice!(0, 2)
                m.message = string
            rescue
                raise "Failed to parse Kick message: #{orig}"
            end
            m
        end
    end
end
end
