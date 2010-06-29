
module MessageFactory
module Handlers
    class YourHost < Handler
        def types_process
            :'002'
        end
        # string:: string to process
        # Create a new YourHost message
        # OpenStruct will contain:
        # #type #direction #raw #received #target #server #version
        # :nodoc: :not.configured 002 spox :Your host is not.configured, running version bahamut-1.8(04)
        def process(string)
            string = string.dup
            orig = string.dup
            m = nil
            begin
                m = mk_struct(string)
                m.type = :yourhost
                string.slice!(0)
                m.server = string.slice!(0, string.index(' '))
                string.slice!(0)
                raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :'002'
                string.slice!(0)
                m.target = string.slice!(0, string.index(' '))
                string.slice!(0, string.rindex(' ')+1)
                m.version = string
            rescue
                raise "Failed to parse YourHost message: #{orig}"
            end
            m
        end
    end
end
end
