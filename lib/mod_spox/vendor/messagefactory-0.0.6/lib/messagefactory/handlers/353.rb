# To change this template, choose Tools | Templates
# and open the template in the editor.

#RPL_NAMREPLY => 353
#RPL_ENDOFNAMES => 366

module MessageFactory
module Handlers
    class Names < Handler
        def initialize
            @cache = {}
        end
        def types_process
            [:'353', :'366']
        end
        # string:: string to process
        # Create a new Names message
        # OpenStruct will contain:
        # #type #direction #raw #received #target #channel #server #nicks
        # :nodoc: :swiftco.wa.us.dal.net 353 spox = #mod_spox :mod_spox spox
        # :nodoc: :swiftco.wa.us.dal.net 366 spox #mod_spox :End of /NAMES list.
        def process(string)
            string = string.dup
            orig = string.dup
            m = nil
            begin
                string.slice!(0)
                server = string.slice!(0, string.index(' '))
                string.slice!(0)
                case string.slice!(0, string.index(' ')).to_sym
                when :'353'
                    m = names(string, orig)
                when :'366'
                    m = end_names(string, orig)
                else
                    raise 'error'
                end
                if(m)
                    m.server = server
                end
            rescue
                raise "Failed to parse Name message: #{orig}"
            end
            m
        end

        def names(string, orig)
            string.slice!(0)
            target = string.slice!(0, string.index(' '))
            string.slice!(0, 3)
            channel = string.slice!(0, string.index(' '))
            m = @cache[channel] ? @cache[channel] : mk_struct(orig)
            m.type = :names
            m.target = target
            m.channel = channel
            if(m.raw.is_a?(Array))
                m.raw.push(orig)
            else
                m.raw = [m.raw]
            end
            string.slice!(0, string.index(':')+1)
            m.nicks ||= []
            m.nicks = m.nicks + string.split
            @cache[channel] = m
            nil
        end

        def end_names(string, orig)
            string.slice!(0)
            string.slice!(0, string.index(' ')+1)
            channel = string.slice!(0, string.index(' '))
            m = nil
            if(@cache[channel])
                m = @cache[channel]
                m.raw.push(orig)
                @cache.delete(channel)
            end
            m
        end
    end
end
end
