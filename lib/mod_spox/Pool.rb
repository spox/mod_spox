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
                        if(Pool.workers > Pool.workers_min)
                            Timeout::timeout(60) do
                                action = @pool.queue.pop
                            end
                        else
                            action = @pool.queue.pop
                        end
                        run(action) unless action.nil?
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
                Logger.warn("Pool worker timed out during execution of action (#{@timeout} sec limit): #{action}")
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
        
        def Pool.workers_min
            return Pool.instance.min
        end
        
        def Pool.workers_max
            return Pool.instance.max
        end
        
        def remove(pt)
            @threads.delete(pt)
            Logger.info("Pool thread has been removed: #{pt}")
        end
        
        def add(action)
            @queue << action
            create_pool_thread if @queue.size > @min
        end
        
        # Return maximum number of seconds actions are allowed to process
        def Pool.worker_timeout
            Pool.instance.timeout
        end

        # time:: number of seconds actions are allowed
        # Set number of seconds actions are allowed to work
        def Pool.worker_timeout=(time)
            Pool.instance.timeout = time
        end

        # Set maximum number of workers to process tasks
        def Pool.workers_max=(max)
            Pool.instance.workers_max = max
        end
        
        # Not currently implemented
        def Pool.workers_min=(min)
            Pool.instance.workers_min = min
        end
        
        attr_reader :threads
        attr_reader :queue
        attr_reader :min
        attr_reader :max
        attr_reader :timeout
    
        def initialize
            @queue = Queue.new
            @threads = []
            @lock = Mutex.new
            @timeout = get_value('pool_timeout', 0).to_i
            @max = Database.type != :pgsql ? 1 : get_value('pool_workers_max', 7).to_i
            @min = Database.type != :pgsql ? 1 : get_value('pool_workers_min', 5).to_i
            @min.times{create_pool_thread}
        end
        
        def create_pool_thread(force=false)
            return nil unless @threads.size < @max || force
            pt = PoolThread.new(self, @timeout)
            @threads << pt
            return pt
        end
        
        def get_value(n, default)
            m = Models::Config.filter(:name => n).first
            return m.nil? ? default : m.value
        end
        
        def set_value(n, v)
            m = Models::Config.find_or_create(:name => n)
            m.value = v
            m.save
        end
        
        def timeout=(v)
            set_value('pool_timeout', v.to_i)
            @timeout = v.to_i
        end
        
        def workers_max=(v)
            set_value('pool_workers_max', v.to_i)
            @max = v.to_i
        end
        
        def workers_min=(v)
            set_value('pool_workers_min', v.to_i)
            @min = v.to_i
        end

    end

end