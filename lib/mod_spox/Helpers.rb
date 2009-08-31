['timeout',
 'net/http',
 'mod_spox/models/Nick',
 'mod_spox/models/Channel',
 'mod_spox/models/Server',
 'mod_spox/models/Models',
 'mod_spox/Logger'].each{|f|require f}

module ModSpox
    module Helpers
        # secs:: number of seconds
        # Converts seconds into a human readable string
        def Helpers.format_seconds(secs)
            arg = {:year => 29030400,
                   :month => 2419200,
                   :week => 604800,
                   :day => 86400,
                   :hour => 3600,
                   :minute => 60,
                   :second => 1}
            res = ''
            arg.each_pair do |k,v|
                z = (secs / v).to_i
                next unless z > 0
                res += " #{z} #{k}#{z == 1 ? '':'s'}"
                secs = secs % v
            end
            res = '0 seconds' if res.empty?
            return res.strip
        end

        # bytes:: number of bytes
        # Converts bytes into easy human readable form
        # O(1) version by Ryan "pizza_milkshake" Flynn
        Suff = [
        "",       # 1024^0
        "Kilo",   # 1024^1
        "Mega",   # 1024^2
        "Giga",   # 1024^3
        "Tera",   # 1024^4
        "Peta",   # 1024^5
        "Exa",    # 1024^6
        "Zetta",  # 1024^7
        "Yotta"   # 1024^8
        ]
        def Helpers.format_size(bytes)
            mag = (Math.log(bytes) / Math.log(1024)).floor
            mag = [ Suff.length - 1, mag ].min
            val = bytes.to_f / (1024 ** mag)
            "%7.3f %sbyte%s" % [ val, Suff[mag], val == 1 ? "" : "s" ]
        end

        # command:: command to execute
        # timeout:: maximum number of seconds to run
        # maxbytes:: maximum number of result bytes to accept
        # Execute a system command (use with care)
        def Helpers.safe_exec(command, timeout=10, maxbytes=500)
            rd,wr = IO.pipe
            result = nil
            cid = Kernel.fork do
                rd.close
                output = []
                pro = nil
                Kernel.trap('HUP'){ Process.kill('KILL', pro.pid) unless pro.nil? } # stop those god awful dance parties
                begin
                    pro = IO.popen(command)
                    until(pro.closed? || pro.eof?)
                        output << pro.getc
                        raise IOError.new("Maximum allowed output bytes exceeded. (#{maxbytes} bytes") unless output.count <= maxbytes
                    end
                    output = output.join('')
                rescue Object => boom
                    output = boom
                ensure
                    output = [Marshal.dump(output)].pack('m')
                    wr.write output
                    wr.close
                    exit
                end
            end
            if(cid)
                wr.close
                begin
                    Timeout::timeout(timeout) do
                        result = rd.read
                    end
                    result = result.size > 0 ? Marshal.load(result.unpack('m')[0]) : ''
                rescue Timeout::Error => boom
                    Process.kill('HUP', cid)
                    raise boom
                rescue Object => boom
                    Process.kill('HUP', cid) unless Process.wait2(cid, WUNTRACED).stopped?
                    raise boom
                ensure
                    Process.wait(cid, Process::WNOHANG)
                end
                raise result if result.is_a?(Exception)
                return result
            end
        end
        
        # url:: URL to shorten
        # Gets a tinyurl for given URL
        def Helpers.tinyurl(url)
            begin
                connection = Net::HTTP.new('tinyurl.com', 80)
                resp, data = connection.get("/api-create.php?url=#{url}")
                if(resp.code !~ /^200$/)
                    raise "Failed to make the URL small."
                end
                return data.strip
            rescue Object => boom
                raise "Failed to process URL. #{boom}"
            end
        end

        # string:: name of target
        # Locates target model and returns it. String can be a nick
        # or channel name. If the string given does not match the required
        # pattern for a channel or nick, the string is returned.
        def Helpers.find_model(string, create=true)
            result = nil
            if(string =~ /^[A-Za-z\|\\\{\}\[\]\^\`~\_\-]+[A-Za-z0-9\|\\\{\}\[\]\^\`~\_\-]*$/)
                result = Models::Nick.find_or_create(:nick => string.downcase)
            elsif(['&', '#', '+', '!'].include?(string[0]))
                result = Models::Channel.find_or_create(:name => string.downcase)
            elsif(Models::Server.filter(:host => string, :connected => true).count > 0)
                result = Models::Server.filter(:host => string, :connected => true).first
            else
                Logger.warn("Failed to match string to model: #{string} -> No match")
            end
            return result
        end

        # string:: string to convert
        # Converts HTML entities found in a string
        def Helpers.convert_entities(string)
            begin
                require 'htmlentities'
                @@coder = HTMLEntities.new unless Helpers.class_variable_defined?(:@@coder)
                return @@coder.decode(string)
            rescue Object
                return string
            end
        end

        # kind:: (:internal|:incoming|:outgoing)
        # type:: message type (Example: :Privmsg)
        # Easy loader for messages
        def Helpers.load_message(kind, type)
            raise ArgumentError.new('Valid kind types: :internal, :incoming, :outgoing') unless [:internal, :incoming, :outgoing].include?(kind)
            require "mod_spox/messages/#{kind}/#{type}"
        end

        # a:: object
        # b:: type constant or string
        # symbolize:: Symbolize and check (deprecated)
        # Determines if a is a type of b. For example:
        # 
        #   a = Foo::Bar.new
        #   Helpers.type_of?(a, Foo) -> true
        def Helpers.type_of?(a, b, symbolize=false)
            return true if (b.is_a?(Class) || b.is_a?(Module)) && a.is_a?(b) # if only it were always this easy
            checks = []
            # first, we strip the front down
            t = a.class.to_s
            unless(t.index('ModSpox::Messages::').nil?)
                t.slice!(t.index('ModSpox::Messages::'), 19)
                checks << t
            end
            t = a.class.to_s
            if(t.slice(0) == '<')
                t.slice!(0, t.rindex('>'))
                checks << t
            end
            checks << a.class.to_s
            checks.each do |s|
                until(s.index('::').nil?) do
                    s.slice!(s.rindex('::'), s.length - s.rindex('::'))
                    return true if s =~ /#{b}.*/
                end
            end
            # one last check if we are allowed to symbolize
            if(symbolize && b.is_a?(Symbol))
                sym = a.class.to_s
                sym.gsub!('::', '_')
                return true if sym == b || b =~ /#{sym}.*/
                sym.slice!(0, 17) if sym.index('ModSpox_Messages') == 0
                sym.slice!(0, sym.index('>')+1) if sym.index('<') == 0 # this is for dynamic objects from plugins
                return true if sym == b || b =~ /#{sym}.*/
            end
            return false
        end
        
        # c:: constant name (String)
        # Finds a constant if it exists
        # Example:: Foo::Bar
        def Helpers.find_const(c)
            return c unless c.is_a?(String)
            const = nil
            [Kernel, ModSpox, Messages].each do |base|
                begin
                    c.split('::').each do |part|
                        const = const.nil? ? base.const_get(part) : const.const_get(part)
                    end
                rescue NameError
                    const = nil
                end
            end
            return const.nil? ? c : const
        end
        
        # IdealizedHumanRandom - select "random" members of a population, favoring
        # those least-recently selected, to appease silly humans who hate repeats
        # Author: Ryan "pizza_" Flynn
        class IdealizedHumanRandom

            def initialize(list)
                raise ArgumentError.new("Expecting Array type. Received: #{list.class}") unless list.is_a?(Array)
                @next = list
            end
        
            # NOTE: corrupted method for generating weighted random number over
            # Gaussian distribution folded in on itself; heavily favors 0
            def self.gauss()
                x = rand() / 1.0
                y = rand() / 1.0
                z = (Math.sqrt(-2.0 * Math.log(x)) * Math.cos(2.0 * Math::PI * y)).abs
                return z
            end
            
            def next()
                i = (IdealizedHumanRandom.gauss() * (@next.size / 5.0)).floor
                @next.push(@next.delete_at(i))  # selected to end, unlikely spot
                return @next.last
            end
            
        end
    end
end