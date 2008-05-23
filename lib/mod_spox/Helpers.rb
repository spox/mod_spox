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
            str = []
            d = (secs / 86400).to_i
            secs = secs % 86400
            h = (secs / 3600).to_i
            secs = secs % 3600
            m = (secs / 60).to_i
            secs = secs % 60
            {:day => d, :hour => h, :minute => m, :second => secs}.each_pair do |type, value|
                if(value > 0)
                    str << "#{value} #{type}#{value == 1 ? '':'s'}"
                end
            end
            return str.join(' ')
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
                Logger.log("Command execution exceeded allowed time (command: #{command} | timeout: #{timeout})")
            rescue Object => boom
                Logger.log("Command generated an exception (command: #{command} | error: #{boom})")
            end
        end
        
        # url:: URL to shorten
        # Gets a tinyurl for given URL
        def Helpers.tinyurl(url)
            begin
                connection = Net::HTTP.new('tinyurl.com', 80)
                resp, data = connection.get("/create.php?url=#{url}", nil)
                if(resp.code !~ /^200$/)
                    raise "Failed to make the URL small."
                end
                data.gsub!(/[\n\r]/, '')
                if(data =~ /<input type=hidden name=tinyurl value="(.+?)">/)
                    return $1
                else
                    raise "Failed to locate the small URL."
                end
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
                Logger.log("Model: #{string} -> Nick", 30)
                nick = nil
                if(@@nick_cache.has_key?(string.to_sym))
                    begin
                        nick = Models::Nick[@@nick_cache[string.to_sym]]
                        Logger.log("Handler cache hit for nick: #{string}", 30)
                        if(nick.nick.downcase != string.downcase)
                            Logger.log("Nick returned from cache invalid. Expecting #{string} but got #{nick.nick}", 30)
                            nick = nil
                        end
                    rescue Object => boom
                        Logger.log("Failed to grab cached nick: #{boom}", 30)
                    end
                end
                unless(nick)
                    nick = Models::Nick.locate(string, create)
                    @@nick_cache[string.to_sym] = nick.pk if nick.is_a?(Models::Nick)
                    Logger.log("Nick was retrieved from database", 30)
                end
                return nick
            elsif(string =~ /^[&#+!]/)
                Logger.log("Model: #{string} -> Channel", 30)
                if(@@channel_cache.has_key?(string.to_sym))
                    begin
                        channel = Models::Channel[@@channel_cache[string.to_sym]]
                        Logger.log("Handler cache hit for channel: #{string}", 30)
                        if(string.downcase != channel.name.downcase)
                            Logger.log("Channel returned from cache invalid. Expecting #{string} but got #{channel.name}", 30)
                            channel = nil
                        end
                    rescue Object => boom
                        Logger.log("Failed to grab cached channel: #{boom}", 30)
                    end
                end
                unless(channel)
                    channel = Models::Channel.locate(string, create)
                    @@channel_cache[string.to_sym] = channel.pk if channel.is_a?(Models::Channel)
                    Logger.log("Channel was retrieved from database", 30)
                end
                return channel
            elsif(model = Models::Server.filter(:host => string, :connected => true).first)
                Logger.log("Model: #{string} -> Server", 30)
                return model
            else
                Logger.log("FAIL Model: #{string} -> No match", 30)
                return string
            end
        end
        
        def Helpers.initialize_caches
            @@nick_cache = Cache.new(30) unless Helpers.class_variable_defined?(:@@nick_cache)
            @@channel_cache = Cache.new(10) unless Helpers.class_variable_defined?(:@@channel_cache)
        end
    end
end