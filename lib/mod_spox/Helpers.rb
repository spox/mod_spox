require 'timeout'
module ModSpox
    module Helpers
        # secs:: number of seconds
        # Converts seconds into a human readable string
        def Helpers.format_seconds(secs)
            d = (secs / 86400).to_i
            secs = secs % 86400
            m = (secs / 3600).to_i
            secs = secs % 3600
            str = Array.new
            str << d == 1 ? "#{d} day" : "#{d} days" if d > 0
            str << m == 1 ? "#{m} minute" : "#{m} minutes" if m > 0
            str << secs == 1 ? "#{secs} second" : "#{secs} seconds" if secs > 0
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
                
    
    end
end