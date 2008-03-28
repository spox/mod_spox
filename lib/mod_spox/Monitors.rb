module ModSpox
    module Monitors    
        
        # The Timer is a time based monitor (thus the
        # "Timer" part of the name)
        class Timer
        
            # Create a new Timer Monitor
            def initialize
                @threads = Array.new
            end
            
            # Force the monitor to wake everyone up
            def wakeup
                @threads.each{|t|t.wakeup}
                @threads.clear
            end
            
            # How long the monitor should wait
            def wait(time=nil)
                @threads << Thread.current
                if(time.nil?)
                    sleep
                else
                    sleep(time)
                end
            end

        end
        
        # The Boolean is a boolean based monitor (thus the
        # "Boolean" part of the name)
        class Boolean
        
            # Create a new Boolean Monitor
            def initialize
                @thread = nil
            end
            
            # Stop waiting
            def wakeup
                Logger.log("Sending wakeup for thread: #{@thread}", 5)
                @thread.run unless @thread == nil
                Logger.log("Status of thread to wakeup: #{@thread.status}", 5)
                Logger.log("Calling thread is: #{Thread.current}", 5)
                @thread = nil
            end
            
            # Start waiting
            def wait
                @thread = Thread.current
                Logger.log("Stopping execution of thread: #{@thread}", 5)
                Thread.stop
            end
        
        end
    end
    
end