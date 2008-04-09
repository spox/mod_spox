require 'timeout'
require 'net/http'
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
    end
end