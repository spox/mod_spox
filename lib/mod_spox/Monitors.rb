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
                @threads = []
            end
            
            # Stop waiting
            def wakeup
                return if @threads.empty?
                @threads.each{|t|t.wakeup}
                @threads.clear
            end
            
            # Start waiting
            def wait
                @threads << Thread.current
                sleep
            end
            
            # Returns if a thread is currently waiting in this monitor
            def thread_waiting?(thread)
                return @threads.include?(thread)
            end
            
            # Removes a thread from the list of waiting. Will be removed automatically
            # if thread has been killed on next call to wakeup
            def remove_thread(thread)
                @threads.delete(thread) if @threads.include?(thread)
            end
        
        end
    end
    
end