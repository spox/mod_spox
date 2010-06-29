module MessageFactory
module Handlers
    class Bounce < Handler

        # Returns type(s) supported
        def types_process
            :'005'
        end

        # string:: string to process
        # Create a new BadNick message
        # OpenStruct will contain:
        # #type #direction #raw #received #server #port
        # :nodoc: 
        def process(string)
            m = nil
            begin
                m = mk_struct(string)
                m.type = :bounce
                orig = string.dup
                2.times{string.slice!(0..string.index(' '))}
                server = string.slice!(0..string.index(',')-1)
                string.slice!(0..string.index(' ',4))
                m.server = server
                m.port = string
            rescue Object => boom
                raise "Failed to parse Bounce string: #{orig}"
            end
            m
        end
    end
end
end
