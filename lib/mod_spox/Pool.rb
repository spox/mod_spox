module ModSpox

    # The Pool class is used to reduce thread creation. When
    # used in conjuntion with a PoolQueue, it provides an easy
    # way to process many objects in an asynchronous manner
    class Pool
    
        @@pools = Array.new
        @@procs = Queue.new
        @@threads = Hash.new
        @@lock = Mutex.new
        @@max_threads = 10
        @@max_thread_life = 60
        @@pool_thread = nil
        @@kill = false
        @@thread_stopper = Monitors::Boolean.new
        
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
        
        def Pool.delete_thread(thread)
            @@threads.delete(thread) if @@threads.has_key?(thread)
            @@thread_stopper.remove_thread(thread)
            thread.kill
            Logger.log("Thread removed from thread pool: #{thread}")
        end
        
        def Pool.max_queue_size
            size = 0
            @@pools.each do |pool|
                size = pool.queue.size if pool.queue.size > size
            end
            return size
        end
        
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
        
        def Pool.start_watcher
            @@pool_thread = Thread.new{
                until(@@kill) do
                begin
                    waiters = Pool.waiting_threads
                    unless(waiters.empty?)
                        waiters.each do |thread|
                            if(Time.now.to_i - @@threads[thread].to_i > @@max_thread_life)
                                Pool.delete_thread(thread)
                            end
                            unless(['sleep', 'run'].include?(thread.status))
                                Pool.delete_thread(thread)
                            end
                        end
                    else
                        if(Pool.max_queue_size > 0)
                            Pool.add_thread
                        end
                    end
                    
                rescue Object => boom
                    Logger.log("Pool watcher caught an error (ignoring): #{boom} #{boom.backtrace.join("\n")}")
                end
                sleep(0.1)
                end
            } if @@pool_thread.nil?
        end
        
        def Pool.wakeup_threads
            @@thread_stopper.wakeup
        end
        
        def Pool.waiting_threads
            waiting = []
            @@threads.each_pair do |thread,time|
                waiting << thread if @@thread_stopper.thread_waiting?(thread)
            end
            return waiting
        end
        
        def Pool.add_pool(pool)
            @@pools << pool
            @@lock.synchronize do
                Pool.start_watcher
            end
        end
        
        def Pool.remove_pool(pool)
            @@pools.delete(pool)
            @@kill = true if @@pools.empty?
        end
        
        attr_reader :proc
        attr_reader :queue
        
        # max_threads:: Maximum number of threads to use
        # Create a new Pool
        def initialize(useless=2)
            @proc = Proc.new{ run_processor }
            @queue = PoolQueue.new
        end
        
        def destroy
            Pool.remove_pool(self)
        end
        
        def start_pool
            Pool.add_pool(self)
        end
        
        def run_processor
            if(@queue.size > 0)
                processor
            end
        end

        def processor
            raise Exceptions::NotImplemented.new('Processor method has not been implemented')
        end
        
        class PoolQueue < Queue
            
            def <<(val)
                push(val)
                Pool.wakeup_threads
            end
        end
    
    end

end