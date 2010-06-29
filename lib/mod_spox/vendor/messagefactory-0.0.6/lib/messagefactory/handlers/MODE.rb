# To change this template, choose Tools | Templates
# and open the template in the editor.
module MessageFactory
module Handlers
    class Mode < Handler
        def types_process
            :MODE
        end
        # string:: string to process
        # Create a new Mode message
        # OpenStruct will contain:
        # #type #direction #raw #received #source #target #channel #modes #set #unset
        # :nodoc: :spax!~spox@host MODE #m +o spax
        # :nodoc: :spax MODE spax :+iw
        def process(string)
            string = string.dup
            orig = string.dup
            m = nil
            self_mode = string.index('!').nil?
            begin
                m = mk_struct(string)
                m.type = :mode
                string.slice!(0)
                m.source = string.slice!(0, string.index(' '))
                string.slice!(0)
                raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :MODE
                string.slice!(0)
                if(self_mode)
                    m.target = string.slice!(0, string.index(' '))
                    string.slice!(0, string.index(':')+1)
                    action = string.slice!(0).chr
                    m.set = action == '+'
                    m.unset = action == '-'
                    m.modes = string
                else
                    m.channel = string.slice!(0, string.index(' '))
                    string.slice!(0)
                    action = string.slice!(0).chr
                    m.set = action == '+'
                    m.unset = action == '-'
                    m.modes = string.slice!(0, string.index(' '))
                    string.slice!(0)
                    m.target = string
                    m.nick_mode = Hash[m.target.split.zip(m.modes.split(''))]
                end
            rescue
                raise "Failed to parse Mode message: #{orig}"
            end
            m
        end
    end
end
end
