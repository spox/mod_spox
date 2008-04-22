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
        @@max_execution_time = 500
        @@pool_thread = nil
        @@kill = false
        
        def Pool.add_thread
            if(@@threads.size < @@max_threads)
                thread = Thread.new do
                    until(@@kill) do
                        Pool.schedule_thread
                    end
                end
                @@threads[thread] = Time.now
                Logger.log("New thread added to thread pool: #{thread}")
            else
                raise BotException.new("Thread maximum reached. Unable to create new threads.")
            end
        end
        
        def Pool.schedule_thread
            proc = nil
            @@lock.synchronize do
                proc = @@procs.pop if @@procs.size > 0
            end
            if(proc.nil?)
                h = nil
                @@pools.each do |holder|
                    h = holder if h.nil? || h[:threads].size > holder[:threads].size
                end
                proc = h[:pool].proc
            end
            begin
                holder = Pool.pool_holder(proc)
                holder[:threads] << Thread.current
                @@threads[Thread.current] = Time.now
                proc.call
                @@threads[Thread.current] = nil
                holder[:threads].delete(Thread.current)
            rescue Object => boom
                Logger.log("Failed to run given proc: #{boom}")
            end
        end
        
        def Pool.trim_threads
            @@threads.each_pair do |thread, time|
                if(thread.status == 'sleep' && (Time.now.to_i - time.to_i) > 20)
                    Logger.log("Removing stale thread from pool: #{thread}")
                    delete = true
                    thread.terminate
                    begin
                        holder = Pool.pool_holder(thread)
                        if(holder[:threads].size == 1)
                            delete = false
                        else
                            holder[:threads].delete(thread)
                        end
                    rescue Object => boom
                        #ignore#
                    end
                    @@threads.delete(thread) if delete
                end
            end
        end
    
        def Pool.start_pools
            @@lock.synchronize do
                @@pool_thread = Thread.new{
                    until(@@kill) do
                        begin
                            Pool.check_pools
                            sleep(0.1)
                        rescue Object => boom
                            Logger.log("Error encountered while checking thread pool. (ignored) #{boom}")
                        end
                    end
                } if @@pool_thread.nil?
            end
        end
        
        def Pool.check_pools
            @@threads.each_pair do |thread,time|
                if([false, nil, 'aborting'].include?(thread.status))
                    @@threads.delete(thread)
                    Pool.pool_holder(thread)[:threads].delete(thread)
                elsif(thread.status == 'run' && !time.nil? && (Time.now.to_i - time.to_i) > @@max_execution_time)
                    Logger.log("Error: Thread has exceeded maximum execution time of #{@@max_execution_time} seconds. (#{thread})")
                    thread.terminate
                elsif(thread.status == 'sleep')
                    @@threads[thread] = Time.now
                end
            end
            @@pools.each do |holder|
                add = nil
                if(holder[:threads].empty?)
                    add = true
                    begin
                        @@procs << holder[:pool].proc
                    rescue Object => boom
                        Logger.log("WE HAVE AN ERROR: #{boom}")
                    end
                end
                holder[:threads].each do |thread|
                    if(thread.status == 'sleep')
                        add = false
                    elsif(thread.status == 'run' && !@@threads[thread].nil? && (Time.now.to_i - @@threads[thread].to_i) > 2 && add.nil?)
                        @@procs << holder[:pool].proc
                        add = true
                    end
                end
                add_thread if add
            end
            Pool.trim_threads
        end
        
        def Pool.add_pool(pool)
            Pool.start_pools
            @@lock.synchronize do
                @@pools << {:pool => pool, :last_process => Time.now, :threads => []}
                @@procs << pool.proc
                Pool.add_thread
            end
        end
        
        def Pool.remove_pool(pool)
            @@lock.synchronize do
                holder = Pool.pool_holder(pool)
                holder[:threads].each do |thread|
                    thread.terminate
                end
                holder[:threads].clear
                @@pools.delete(holder)
            end
            @@kill = true if @@pools.empty?
        end
        
        def Pool.max_threads=(num)
            num = num.to_i
            @@lock.synchronize do
                @@max_threads = num if num > 0 && num > @@pools.size
            end
        end
        
        def Pool.pool_holder(object)
            @@pools.each do |holder|
                return holder if object.is_a?(Pool) && holder[:pool] == object
                return holder if object.is_a?(Proc) && holder[:pool].proc == object
                return holder if object.is_a?(Thread) && holder[:threads].include?(object)
            end
            raise Exceptions::BotException.new('Failed to locate given pool')
        end
        
        attr_reader :proc
        
        # max_threads:: Maximum number of threads to use
        # Create a new Pool
        def initialize(useless=2)
            @proc = Proc.new{ run_processor }
        end
        
        def destroy
            Pool.remove_pool(self)
        end
        
        def start_pool
            Pool.add_pool(self)
        end
        
        def run_processor
            processor
        end

        def processor
            raise Exceptions::NotImplemented.new('Processor method has not been implemented')
        end
    
    end

end