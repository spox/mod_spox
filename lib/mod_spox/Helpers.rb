['timeout',
 'net/http',
 'mod_spox/models/Nick',
 'mod_spox/models/Channel',
 'mod_spox/models/Server',
 'mod_spox/Cache',
 'mod_spox/Logger'].each{|f|require f}

module ModSpox
    module Helpers
        # secs:: number of seconds
        # Converts seconds into a human readable string
        def Helpers.format_seconds(secs)
            str = {}
            d = (secs / 86400).to_i
            secs = secs % 86400
            h = (secs / 3600).to_i
            secs = secs % 3600
            m = (secs / 60).to_i
            secs = secs % 60
            {:day => d, :hour => h, :minute => m, :second => secs}.each_pair do |type, value|
                if(value > 0)
                    str[type] = "#{value} #{type}#{value == 1 ? '':'s'}"
                end
            end
            output = ''
            [:day, :hour, :minute, :second].each do |type|
                output += str[type] + ' ' if str.has_key?(type)
            end
            output = '0 seconds' if output.empty?
            return output.strip
        end

        # bytes:: number of bytes
        # Converts bytes into easy human readable form
        # O(1) version by Ryan "pizza_milkshake" Flynn
        Suff = [
        "",       # 1000^0
        "Kilo",   # 1000^1
        "Mega",   # 1000^2
        "Giga",   # 1000^3
        "Tera",   # 1000^4
        "Peta",   # 1000^5
        "Exa",    # 1000^6
        "Zetta",  # 1000^7
        "Yotta"   # 1000^8
        ]
        def Helpers.format_size(bytes)
            mag = (Math.log(bytes) / Math.log(1000)).floor
            mag = [ Suff.length - 1, mag ].min
            val = bytes.to_f / (1000 ** mag)
            "%7.3f %sbyte%s" % [ val, Suff[mag], val == 1 ? "" : "s" ]
        end

        # command:: command to execute
        # timeout:: maximum number of seconds to run
        # Execute a system command (use with care)
        def Helpers.safe_exec(command, timeout=10)
            begin
                Timeout::timeout(timeout) do
                    result = `#{command}`
                end
            rescue Timeout::Error => boom
                Logger.warn("Command execution exceeded allowed time (command: #{command} | timeout: #{timeout})")
                raise "Command execution exceeded allowed time (timeout: #{timeout})"
            rescue Object => boom
                Logger.warn("Command generated an exception (command: #{command} | error: #{boom})")
                raise "Command generated an exception: #{boom}"
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
            Helpers.initialize_caches
            if(string =~ /^[A-Za-z\|\\\{\}\[\]\^\`~\_\-]+[A-Za-z0-9\|\\\{\}\[\]\^\`~\_\-]*$/)
                nick = nil
                if(@@nick_cache.has_key?(string.downcase.to_sym))
                    begin
                        nick = Models::Nick[@@nick_cache[string.downcase.to_sym]]
                        if(nick.nick.downcase != string.downcase)
                            Logger.warn("Nick returned from cache invalid. Expecting #{string} but got #{nick.nick}")
                            nick = nil
                        end
                    rescue Object => boom
                        Logger.info("Failed to grab cached nick: #{boom}")
                    end
                end
                unless(nick)
                    begin
                        nick = Models::Nick.locate(string, create)
                        if(nick.nil?)
                            Database.reconnect
                            return string
                        end
                    rescue Object => boom
                        Logger.warn("Caught an error. Assuming the database barfed: #{boom}")
                        Database.reconnect
                    end
                    @@nick_cache[string.downcase.to_sym] = nick.pk if nick.is_a?(Models::Nick)
                    Logger.info('Nick was retrieved from database')
                end
                return nick
            elsif(string =~ /^[&#+!]/)
                if(@@channel_cache.has_key?(string.downcase.to_sym))
                    begin
                        channel = Models::Channel[@@channel_cache[string.downcase.to_sym]]
                        if(string.downcase != channel.name.downcase)
                            Logger.warn("Channel returned from cache invalid. Expecting #{string} but got #{channel.name}")
                            channel = nil
                        end
                    rescue Object => boom
                        Logger.info("Failed to grab cached channel: #{boom}")
                    end
                end
                unless(channel)
                    channel = Models::Channel.locate(string, create)
                    if(channel.nil?)
                        Database.reconnect
                        return string
                    end
                    @@channel_cache[string.downcase.to_sym] = channel.pk if channel.is_a?(Models::Channel)
                    Logger.info('Channel was retrieved from database')
                end
                return channel
            elsif(model = Models::Server.filter(:host => string, :connected => true).first)
                return model
            else
                Logger.warn("Failed to match string to model: #{string} -> No match")
                return string
            end
        end

        def Helpers.initialize_caches
            @@nick_cache = Cache.new(20) unless Helpers.class_variable_defined?(:@@nick_cache)
            @@channel_cache = Cache.new(5) unless Helpers.class_variable_defined?(:@@channel_cache)
        end
    end
end