# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
    class Part < Handler
        def types_process
            :PART
        end
        # string:: string to process
        # Create a new Part message
        # OpenStruct will contain:
        # #type #direction #raw #received #source #channel #message
        # :nodoc: :mod_spox!~mod_spox@host PART #m :
        # :nodoc: :foobar!~foobar@some.host PART #php
        def process(string)
            string = string.dup
            m = mk_struct(string)
            begin
                m.type = :part
                string.slice!(0)
                m.source = string.slice!(0, string.index(' '))
                string.slice!(0)
                raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :PART
                string.slice!(0)
                m.channel = string.slice!(0, string.index(' '))
                if(string.index(':'))
                    string.slice!(0, string.index(':')+1)
                    m.message = string
                else
                    m.message = ''
                end
            rescue
                raise "Failed to parse Part message: #{m.raw}"
            end
            m
        end
    end
end
end
