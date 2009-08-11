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
            output = []
            begin
                Timeout::timeout(timeout) do
                    pro = IO.popen(command)
                    until((output << pro.getc).nil?) do
                        raise IOError.new unless output.count <= maxbytes
                    end
                    return output.join('')
                end
            rescue Timeout::Error => boom
                Logger.warn("Command execution exceeded allowed time (command: #{command} | timeout: #{timeout})")
                raise boom
            rescue Object => boom
                Logger.warn("Command generated an exception (command: #{command} | error: #{boom})")
                raise boom
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
        def load_message(kind, type)
            require "mod_spox/messages/#{kind}/#{type}"
        end
    end
end