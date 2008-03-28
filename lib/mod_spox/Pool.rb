module ModSpox

    # The Pool class is used to reduce thread creation. When
    # used in conjuntion with a PoolQueue, it provides an easy
    # way to process many objects in an asynchronise manner
    class Pool
    
        # num_procs:: Number of threads to use
        # Create a new Pool
        def initialize(num_procs=2)
            @num_threads = num_procs
            @threads = Array.new
            @kill = false
        end
        
        # Stop all the running threads
        def destroy
            @kill = true
            @threads.each{|t|
                Logger.log("Shutting down thread: #{t} in #{self.class.to_s}", 10)
                t.exit
            }
            sleep(0.1)
        end
        
        # Starts the pool
        def start_pool
            @num_threads.times do
                @threads << Thread.new{
                    until @kill do
                        processor
                    end
                }
            end
        end
        
        # Method the pool uses to do stuff.
        # (It is important to note that using this can
        # very easily eat up all your CPU time. The Processor
        # method must yield at some point, otherwise it will
        # just continue to loop, even if it is doing nothing.
        # This is the reason for the PoolQueue as this Pool
        # was created as a way to quickly process messages)
        def processor
            raise Exceptions::NotImplemented.new('Processor method has not been implemented')
        end
    
    end

end