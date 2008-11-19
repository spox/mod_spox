['mod_spox/Logger',
 'mod_spox/Exceptions',
 'timeout'].each{|f|require f}

module ModSpox

    # The Pool class is used to reduce thread creation. It provides
    # an easy way to process many actions in an asynchronous manner.
    class Pool
    
        # Create and start our process pool
        # Note: This uses a separate thread to run the actions. This is not
        # needed on 1.8.x as the fibers are simulated there, but in 1.9 errors
        # will occur as attempts to call fibers are made across threads
    
        def Pool.create_pool
            workers_max = Models::Config.filter(:name => 'pool_workers_max').first
            workers_max = workers_max.nil? ? 30 : workers_max.value.to_i
            timeout = Models::Config.filter(:name => 'pool_timeout').first
            @@timeout = timeout.nil? ? 15 : timeout.value.to_i
            @@queue = Queue.new
            Thread.new do
                @@pool = NeverBlock::Pool::FiberPool.new(workers_max)
                @@kill = false
                until @@kill do
                    a = @@queue.pop
                    Pool.run(a)
                end
            end
        end
        
        # Stop processing actions in the pool
        def Pool.stop_pool
            @@kill = true
        end
        
        # Add an action to the pool to be processed
        def Pool.<<(action)
            @@queue << action
        end
        
        # Alias of Pool.<<(action)
        def Pool.queue(action)
            Pool << action
        end
        
        # action:: action to be run
        # Runs an action in the pool
        def Pool.run(action)
            @@pool.spawn do
                begin
                    if(@@timeout > 0)
                        Timeout::timeout(@@timeout) do
                            action.call
                        end
                    else
                        action.call
                    end
                rescue Timeout::Error => boom
                    Logger.warn("Pool worker timed out during execution of action (#{@@timeout} sec limit)")
                rescue Object => boom
                    Logger.warn("Pool worker caught an unknown exception: #{boom}")
                end
            end
        end

        # Return maximum number of seconds actions are allowed to process
        def Pool.max_exec_time
            @@timeout
        end

        # time:: number of seconds actions are allowed
        # Set number of seconds actions are allowed to work
        def Pool.max_exec_time=(time)
            @@timeout = time
            t = Models::Config.find_or_create(:name => 'pool_timeout')
            t.value = time
            t.save
        end

        # returns maximum number of workers
        def Pool.max_workers
            t = Models::Config.filter(:name => 'pool_workers_max').first
            return t.nil? ? 30 : t.value
        end

        # Set maximum number of workers to process tasks
        def Pool.max_workers=(max)
            t = Models::Config.find_or_create(:name => 'pool_workers_max')
            t.value = max
            t.save
        end
        
        # Not currently implemented
        def Pool.min_workers
            'not implemented'
        end
        
        # Not currently implemented
        def Pool.min_workers=(min)
            'not implemented'
        end

        def Pool.workers
            @@pool.fibers.size
        end

    end

end