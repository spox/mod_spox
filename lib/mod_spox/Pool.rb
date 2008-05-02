module ModSpox

    # The Pool class is used to reduce thread creation. It provides
    # an easy way to process many objects in an asynchronous manner.
    class Pool
    
        # 
        def Pool.max_threads(num=nil)
            if(num.nil?)
                return @@max_threads
            else
                num = num.to_i
                raise Exceptions::InvalidValue.new('Maximum threads setting must be a positive integer') if num < 1
                @@max_threads = num
            end
        end
        
        def Pool.max_thread_life(num=nil)
            if(num.nil?)
                return @@max_thread_life
            else
                num = num.to_i
                raise Exceptions::InvalidValue.new('Maximum thread life setting must be a positive integer') if num < 1
                @@max_thread_life = num
            end
        end

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
        @@threads = Hash.new
        # Lock for thread safety
        @@lock = Mutex.new
        # Maximum number of threads in pool
        @@max_threads = 10
        # Maximum number of seconds a thread may spend waiting for an action
        @@max_thread_life = 60
        # Thread to tend to pool actions
        @@pool_thread = nil
        # Informs threads to halt
        @@kill = false
        # Place for threads to wait for actions
        @@thread_stopper = Monitors::Boolean.new
        # Timer for the Pool thread
        @@watcher_timer = Monitors::Timer.new
        
        # Adds a new thread to the pool
        def Pool.add_thread
            if(@@threads.size < @@max_threads)
                thread = Thread.new do
                    sleep(0.01)
                    until(@@kill) do
                        Pool.schedule_thread
                    end
                end
                @@threads[thread] = Time.now
                Logger.log("New thread added to pool: #{thread}")
            else
                raise Exceptions::BotException.new("Reached maximum thread pool size: #{@@max_threads} threads")
            end
        end
        
        # thread:: Thread to delete
        # Removes thread from pool
        def Pool.delete_thread(thread)
            @@lock.synchronize do
                @@threads.delete(thread) if @@threads.has_key?(thread)
                @@thread_stopper.remove_thread(thread)
                thread.kill
                Logger.log("Thread removed from thread pool: #{thread}")
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
                @@threads[Thread.current] = Time.now
                run_pool.proc.call
                @@threads[Thread.current] = Time.now
            else
                @@thread_stopper.wait
            end
        end
        
        # Starts the master thread for Pool maintanence
        def Pool.start_watcher
            @@pool_thread = Thread.new{
                until(@@kill) do
                    sleep_time = 0
                    begin
                        waiters = Pool.waiting_threads
                        unless(waiters.empty?)
                            waiters.each do |thread|
                                time = Time.now.to_i - @@threads[thread].to_i
                                sleep_time = (@@max_thread_life - time).to_i if sleep_time = 0 || (@@max_thread_life - time).to_i < sleep_time
                                if(time > @@max_thread_life)
                                    Pool.delete_thread(thread)
                                elsif([nil, false, 'sleep', 'aborting'].include?(thread.status))
                                    Pool.delete_thread(thread)
                                end
                            end
                        else
                            if(Pool.max_queue_size > 0)
                                Pool.add_thread
                            end
                        end
                    rescue Object => boom
                        Logger.log("Pool watcher caught an error (ignoring): #{boom}")
                    end
                    sleep_time = 1 if sleep_time == 0
                    sleep_time = nil if sleep_time < 0
                    Logger.log("Pool watcher thread is now sleeping for: #{sleep_time.nil? ? 'forever' : "#{sleep_time} seconds"}")
                    @@watcher_timer.wait(sleep_time)
                end
            } if @@pool_thread.nil?
        end
        
        # Forces sleeping threads to wake up
        def Pool.wakeup_threads
            @@watcher_timer.wakeup
            @@thread_stopper.wakeup
        end
        
        # Returns list of threads currently waiting for an action to process
        def Pool.waiting_threads
            waiting = []
            @@threads.each_pair do |thread,time|
                waiting << thread if @@thread_stopper.thread_waiting?(thread)
            end
            return waiting
        end
        
        # Adds a Pool to the master Pool list        
        def Pool.add_pool(pool)
            @@pools << pool
            @@lock.synchronize do
                Pool.start_watcher
            end
        end
        
        # Removes a Pool from the master Pool list
        def Pool.remove_pool(pool)
            @@pools.delete(pool)
            @@kill = true if @@pools.empty?
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
                    Pool.wakeup_threads
                end
            end
            
            def push(val)
                @lock.synchronize do
                    super
                    Pool.wakeup_threads
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