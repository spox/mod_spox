
module MessageFactory
module Handlers
    class BadNick < Handler        
        # Returns type(s) supported
        def types_process
            :'432'
        end
        # string:: string to process
        # Create a new BadNick message
        # OpenStruct will contain:
        # #type #direction #raw #bad_nick #received
        # :nodoc: ':the.server 432 spox 999 :Erroneous Nickname'
        def process(string)
            m = nil
            string = string.dup
            orig = string.dup
            begin
                m = mk_struct(string)
                m.type = :badnick
                string.slice!(0)
                m.server = string.slice!(0, string.index(' '))
                string.slice!(0)
                raise unless string.slice!(0, string.index(' ')).to_sym == :'432'
                2.times{string.slice!(0, string.index(' ')+1)}
                m.bad_nick = string.slice!(0, string.index(' '))
            rescue
                raise "Failed to parse BadNick string: #{orig}"
            end
            m
        end
    end
end
end
