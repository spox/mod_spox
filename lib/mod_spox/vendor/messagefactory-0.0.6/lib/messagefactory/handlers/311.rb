# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
    class Whois < Handler
        def initialize
            @cache = {}
        end
        def clear_cache
            @cache.clear
        end
        def types_process
            [:'311', :'319', :'312', :'307', :'330', :'317', :'318', :'378']
        end
        # string:: string to process
        # Create a new Mode message
        # OpenStruct will contain:
        # #type #direction #raw #received #source #target #channels #voice #ops 
        # #irc_host #idle #signon #nickserv
        def process(string)
            string = string.dup
            orig = string.dup
            m = nil
            begin
                string.slice!(0)
                server = string.slice!(0, string.index(' '))
                string.slice!(0)
                action = string.slice!(0, string.index(' '))
                raise unless types_process.include?(action.to_sym)
                string.slice!(0)
                action = ('process_'+action)
                if(self.methods.include?(action))
                    m = self.send(action, string, orig)
                else
                    m = store_raw(string, orig)
                end
                m.source = server if m
            rescue => boom
                raise "Failed to parse Whois message: #{orig}"
            end
            m
        end

        def store_raw(string, orig)
            parts = string.split
            m = @cache[parts[1]]
            raise unless m
            m.raw << orig
            nil
        end

        #:swiftco.wa.us.dal.net 311 spox spox ~spox pool-96-225-201-176.ptldor.dsl-w.verizon.net * :spox
        def process_311(string, orig)
            m = mk_struct(orig)
            m.raw = [orig]
            m.type = :whois
            parts = string.split
            m.target = parts[1]
            m.username = parts[2]
            m.host = parts[3]
            parts[5].slice!(0)
            m.real_name = parts[5]
            @cache[m.target] = m
            nil
        end
        #:swiftco.wa.us.dal.net 319 spox spox :+#php #ruby #mysql @#mod_spox
        def process_319(string, orig)
            parts = string.split
            parts.shift
            m = @cache[parts.shift]
            raise unless m
            m.raw << orig
            parts[0].slice!(0)
            parts.each do |chan|
                start = chan[0,1]
                case start
                when '+'
                    chan.slice!(0)
                    m.voice ||= []
                    m.voice << chan
                when '@'
                    chan.slice!(0)
                    m.ops ||= []
                    m.ops << chan
                end
                m.channels ||= []
                m.channels << chan
            end
            nil
        end
        #:swiftco.wa.us.dal.net 317 spox spox 529 1265393189 :seconds idle, signon time
        def process_317(string, orig)
            parts = string.split
            parts.shift
            m = @cache[parts.shift]
            raise unless m
            m.raw << orig
            m.idle = parts.shift.to_i
            m.signon = parts.shift.to_i
            nil
        end
        #:swiftco.wa.us.dal.net 312 spox spox swiftco.wa.us.dal.net :www.swiftco.net - Swift Communications
        def process_312(string, orig)
            parts = string.split
            parts.shift
            m = @cache[parts.shift]
            raise unless m
            m.raw << orig
            m.irc_host = parts.shift
            nil
        end
        #:swiftco.wa.us.dal.net 307 spox spox :has identified for this nick
        def process_307(string, orig)
            parts = string.split
            parts.shift
            m = @cache[parts.shift]
            raise unless m
            m.nickserv = :identified
            m.raw << orig
            nil
        end
        #:wolfe.freenode.net 330 spox spox spox :is logged in as
        def process_330(string, orig)
            process_307(string, orig)
        end
        #:wolfe.freenode.net 318 spox spox :End of /WHOIS list.
        def process_318(string, orig)
            parts = string.split
            parts.shift
            target = parts.shift
            m = @cache[target]
            raise unless m
            m.raw << orig
            @cache.delete(target)
            m
        end
    end
end
end
