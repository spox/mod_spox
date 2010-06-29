# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
    class Ping < Handler
        def types_process
            :PING
        end
        # string:: string to process
        # Create a new Ping message
        # OpenStruct will contain:
        # #type #direction #raw #received #server #message
        # :nodoc: PING :not.configured
        # :nodoc: :not.configured PING :test
        def process(string)
            string = string.dup
            m = mk_struct(string)
            begin
                m.type = :ping
                if(string.slice(0).chr == ':')
                    string.slice!(0)
                    m.server = string.slice!(0, string.index(' '))
                    string.slice!(0)
                    raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :PING
                    string.slice!(0, string.index(':')+1)
                    m.message = string
                else
                    raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :PING
                    string.slice!(0, string.index(':')+1)
                    m.server = string
                    m.message = string
                end
            rescue
                raise "Failed to parse Ping message: #{m.raw}"
            end
            m
        end
    end
end
end
