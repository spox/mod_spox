['mod_spox/Logger',
 'mod_spox/Exceptions',
 'mod_spox/Monitors',
 'timeout'].each{|f|require f}
 
module ModSpox

    # The Pool class is used to reduce thread creation. It provides
    # an easy way to process many actions in an asynchronous manner.
    class Pool
    
        # Action thread is to perform
        attr_reader :proc
        # Storage space that the pool will be processing
        attr_reader :queue
        
        # Create a new pool
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
                Logger.log("Pool encountered an error processing code block: #{boom}", 99)
            end
        end

        # Action the pool is responsible for. This is the method
        # the child class should override
        def processor
            raise Exceptions::NotImplemented.new('Processor method has not been implemented')
        end
        
        # Running pools
        @@pools = Array.new
        # Threads running in pool
        @@threads = Array.new
        # Schedule lock for thread safety
        @@schedule_lock = Mutex.new
        # Thread creation lock
        @@thread_lock = Mutex.new
        # Maximum number of seconds a thread may spend waiting for an action
        @@max_exec_time = 60
        # Maximum number of threads to process Pool
        @@max_threads = 10
        # Maxium wait time (max time for threads to wait for new action to process)
        @@max_wait_time = 20
        # Monitor for threads to wait in
        @@stop_point = Monitors::Timer.new
        # Informs threads to halt
        @@kill = false
        
        # Adds a new thread to the pool
        def Pool.add_thread(force=false)
            puts "Size of pool threads: #{@@threads.size}"
            if(force || @@threads.size < @@max_threads)
                thr = Thread.new do
                    Pool.schedule_thread
                end
                @@threads << thr
            end
            @@stop_point.wakeup
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
            @@schedule_lock.synchronize do
                @@pools.each do |pool|
                    run_pool = pool if (run_pool.nil? && pool.queue.size > 0) || (!run_pool.nil? && (run_pool.queue.size < pool.queue.size))
                end
            end
            if(run_pool.nil?)
                @@threads.delete(Thread.current)
                return
            else
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
            start = Time.now
            @@stop_point.wait(@@max_wait_time) if Pool.max_queue_size < 1
            if((Time.now - start).to_i < @@max_wait_time)
                Pool.schedule_thread
            else
                @@threads.delete(Thread.current)
                @@threads.each do |thread|
                    @@threads.delete(thread) unless thread.alive?
                end
            end
        end
        
        # Forces sleeping threads to wake up
        def Pool.process
            @@thread_lock.synchronize do
                Pool.add_thread if Pool.max_queue_size > 0
            end
        end
        
        # Adds a Pool to the master Pool list        
        def Pool.add_pool(pool)
            @@pools << pool
        end
        
        # Removes a Pool from the master Pool list
        def Pool.remove_pool(pool)
            @@pools.delete(pool)
            if(@@pools.empty?)
                @@kill = true
                @@stop_point.wakeup
                sleep(0.1)
                @@threads.each{|t| t.kill if t.alive?}
            end
        end
        
        # Modified Queue to properly interact with Pool
        class PoolQueue < Queue
        
            def initialize
                super
                @lock = Mutex.new
            end
            
            def <<(val)
                push(val)
            end
            
            def push(val)
                @lock.synchronize do
                    super
                end
                Pool.process
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