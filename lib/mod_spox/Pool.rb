module ModSpox

    # The Pool class is used to reduce thread creation. It provides
    # an easy way to process many objects in an asynchronous manner.
    class Pool

        # Action thread is to perform
        attr_reader :proc
        # Storage space that the pool will be processing
        attr_reader :queue
        
        # Create a new Pool
        def initialize
            @proc = Proc.new{ run_processor }
            @queue = PoolQueue.new
        end
        
        # Destroys this pool
        def destroy
            Pool.remove_pool(self)
        end
        
        # Starts the pool
        def start_pool
            Pool.add_pool(self)
        end
        
        private 
        
        def run_processor
            begin
                processor
            rescue Object => boom
                Logger.log("Pool encountered an error processing code block: #{boom}")
            end
        end

        def processor
            raise Exceptions::NotImplemented.new('Processor method has not been implemented')
        end
        
        # Running pools
        @@pools = Array.new
        # Threads running in pool
        @@threads = Array.new
        # Lock for thread safety
        @@lock = Mutex.new
        # Maximum number of seconds a thread may spend waiting for an action
        @@max_exec_time = 60
        # Informs threads to halt
        @@kill = false
        
        # Adds a new thread to the pool
        def Pool.add_thread
            @@threads << Thread.new do
                until(Pool.max_queue_size < 1 || @@kill) do
                    Pool.schedule_thread
                end
                Logger.log("Found myself in thread array") if @@threads.include?(Thread.current)
                Logger.log("Failed to find myself in thread array") unless @@threads.include?(Thread.current)
                @@threads.delete(Thread.current)
            end
        end
        
        # Returns the largest queue size of all available pools
        def Pool.max_queue_size
            size = 0
            @@pools.each do |pool|
                size = pool.queue.size if pool.queue.size > size
            end
            return size
        end
        
        # Schedules a thread within the pool
        def Pool.schedule_thread
            run_pool = nil
            @@lock.synchronize do
                @@pools.each do |pool|
                    run_pool = pool if (run_pool.nil? && pool.queue.size > 0) || (!run_pool.nil? && (run_pool.queue.size < pool.queue.size))
                end
            end
            unless(run_pool.nil?)
                begin
                    Timeout::timeout(@@max_exec_time) do
                        run_pool.proc.call
                    end
                rescue Timeout::Error => boom
                    Logger.log("Thread reached maximum execution time (#{@max_exec_time}) processing pool item")
                rescue Object => boom
                    Logger.log("Thread encountered error processing pool item: #{boom}")
                end
            end
        end
        
        # Forces sleeping threads to wake up
        def Pool.process
            sleep(0.1)
            Pool.add_thread if Pool.max_queue_size > 0
            Logger.log("Current number of threads: #{@@threads.size}")
            Logger.log("Total number of threads in use system-wide: #{Thread.list.size}")
        end
        
        # Adds a Pool to the master Pool list        
        def Pool.add_pool(pool)
            @@pools << pool
        end
        
        # Removes a Pool from the master Pool list
        def Pool.remove_pool(pool)
            @@pools.delete(pool)
            sleep(0.1)
            @@threads.each{|t| t.kill} if @@pools.empty?
        end
        
        # Modified Queue to properly interact with Pool
        class PoolQueue < Queue
        
            def initialize
                super
                @lock = Mutex.new
            end
            
            def <<(val)
                @lock.synchronize do
                    super
                    Pool.process
                end
            end
            
            def push(val)
                @lock.synchronize do
                    super
                    Pool.process
                end
            end
            
            def pop
                @lock.synchronize do
                    if(size > 0)
                        super
                    else
                        raise Exceptions::BotException.new("Queue is currently empty")
                    end
                end
            end
                
        end
    
    end

end