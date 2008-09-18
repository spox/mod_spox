['mod_spox/Logger',
 'mod_spox/Exceptions',
 'mod_spox/Monitors',
 'mod_spox/ThreadPool',
 'timeout'].each{|f|require f}

module ModSpox

    # The Pool class is used to reduce thread creation. It provides
    # an easy way to process many actions in an asynchronous manner.
    class Pool

        # Storage space that the pool will be processing
        attr_reader :queue

        # Create a new pool
        def initialize
            if(@@thread_pool.nil?)
                workers = Models::Config[:pool_workers]
                workers = workers.nil? ? 5 : workers.to_i
                timeout = Models::Config[:pool_timeout]
                timeout = timeout.nil? ? 0 : timeout.to_i
                Logger.log("Starting up thread pool with max workers at: #{workers} and timeout: #{timeout} seconds")
                @@thread_pool = ThreadPool.new(workers, timeout)
            end
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

        # Running pools
        @@pools = Hash.new
        @@thread_pool = nil
        @@lock = Mutex.new
        @@running = false

        def Pool.max_exec_time
            @@thread_pool.max_exec_time
        end

        def Pool.max_exec_time=(time)
            @@thread_pool.max_exec_time = time
        end

        def Pool.max_workers
            @@thread_pool.max_workers
        end

        def Pool.max_workers=(max)
            @@thread_pool.max_workers = max
        end

        def Pool.workers
            @@thread_pool.pool_size
        end

        def Pool.stop_old_workers(secs)
            @@thread_pool.clean_old(secs)
        end

        # Forces sleeping threads to wake up
        def Pool.process(action)
            raise Exceptions::InvalidType.new("Pool will only run Procs") unless action.is_a?(Proc)
            @@thread_pool.queue(action)
        end

        # Adds a Pool to the master Pool list
        def Pool.add_pool(pool)
            @@pools[pool.queue.object_id] = pool
        end

        # Removes a Pool from the master Pool list
        def Pool.remove_pool(pool)
            @@pools.delete(pool.queue.object_id)
        end

        # Modified Queue to properly interact with Pool
        class PoolQueue

            def <<(val)
                push(val)
            end

            def push(val)
                Pool.process(val)
            end

            def pop
                raise EmptyQueue.new("Queue is currently empty")
            end
        end

        class EmptyQueue < Exceptions::BotException
        end

    end

end