# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
    class Nick < Handler
        def types_process
            :NICK
        end
        # string:: string to process
        # Create a new Nick message
        # OpenStruct will contain:
        # #type #direction #raw #received #source #new_nick
        # :nodoc: :spox!~spox@some.random.host NICK :flock_of_deer
        def process(string)
            string = string.dup
            m = mk_struct(string)
            begin
                m.type = :nick
                string.slice!(0)
                m.source = string.slice!(0, string.index(' '))
                string.slice!(0)
                raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :NICK
                string.slice!(0, string.index(' ')+2)
                m.new_nick = string
            rescue
                raise "Failed to parse Nick message: #{m.raw}"
            end
            m
        end
    end
end
end
