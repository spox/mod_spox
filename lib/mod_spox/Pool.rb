['mod_spox/Logger',
 'mod_spox/Exceptions',
 'timeout',
 'singleton'].each{|f|require f}

module ModSpox

    class PoolThread
        def initialize(pool, timeout)
            @pool = pool
            @timeout = timeout
            @kill = false
            @thread = Thread.new do
                until @kill do
                    begin
                        action = nil
                        if(Pool.workers > 1)
                            Timeout::timeout(60) do
                                action = @pool.queue.pop
                            end
                        else
                            action = @pool.queue.pop
                        end
                        run(action)
                    rescue Timeout::Error => boom
                        @kill = true
                    rescue Object => boom
                        Logger.warn("Pool thread error: #{boom}")
                    end
                end
                @pool.remove(self)
            end
        end
        
        private
        
        def run(action)
            begin
                if(@timeout > 0)
                    Timeout::timeout(@timeout) do
                        action.call
                    end
                else
                    action.call
                end
            rescue Timeout::Error => boom
                Logger.warn("Pool worker timed out during execution of action (#{@timeout} sec limit)")
            rescue Object => boom
                Logger.warn("Pool worker caught an unknown exception: #{boom}")
            end
        end
    end

    # The Pool class is used to reduce thread creation. It provides
    # an easy way to process many actions in an asynchronous manner.
    class Pool
    
        include Singleton

        # Add an action to the pool to be processed
        def Pool.<<(action)
            Pool.instance.add(action)
        end
        
        # Alias of Pool.<<(action)
        def Pool.queue(action)
            Pool << action
        end
        
        def Pool.workers
            Pool.instance.threads.size
        end
        
        def Pool.sleepers
            'not implemented'
        end
        
        def remove(pt)
            @threads.delete(pt)
            Logger.info("Pool thread has been removed: #{pt}")
        end
        
        def add(action)
            @queue << action
            create_pool_thread if @queue.size > @min
        end
        
        attr_reader :threads
        attr_reader :queue
        
        private
    
        def initialize
            @queue = Queue.new
            @threads = []
            @lock = Mutex.new
            @timeout = 0
            @max = Database.type != :pgsql ? 1 : 50
            @min = Database.type != :pgsql ? 1 : 9
            @min.times{create_pool_thread}
        end
        
        def create_pool_thread(force=false)
            return nil unless @threads.size < @max || force
            pt = PoolThread.new(self, @timeout)
            @threads << pt
            return pt
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

    end

end