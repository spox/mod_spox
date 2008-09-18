require 'mod_spox/Monitors'
require 'timeout'

module ModSpox
    class ThreadPool

        attr_reader :max_workers
        attr_reader :max_exec_time

        def initialize(max_size=10, max_exec_time=0)
            @max_workers = max_size.to_i
            @max_exec_time = max_exec_time.to_i
            @workers = []
            @lock = Mutex.new
            @proc_queue = Queue.new
            @worker_queue = Queue.new
        end

        def max_workers=(max)
            raise Exceptions::InvalidValue.new('Value given must be a positive integer') unless max.to_i > 0
            @max_workers = max.to_i
            resize
        end

        def max_exec_time=(max)
            raise Exceptions::InvalidValue.new('Value given must be a positive integer or zero') unless max.to_i >= 0
            @max_exec_time = max.to_i
        end

        def pool_size
            return @workers.size
        end

        def queue(action)
            @proc_queue << action
            create if @proc_queue.size > @workers.size
        end

        def run(&block)
            @lock.synchronize do
                worker = find_or_create
                if(worker.nil?)
                    @proc_queue << block
                else
                    @workers[worker] = Time.now
                    worker.process(@max_exec_time, &block)
                end
            end
        end

        def clean_old(secs)
            @workers.each do |worker|
                Logger.log("Checking worker time is: #{Time.now.to_i - worker.last_run.to_i} against: #{secs}")
                if((Time.now.to_i - worker.last_run.to_i > secs) && @workers.size > 1)
                    @workers.delete(worker) if worker.kill(0.1)
                end
            end
        end

        def pending_tasks
            @proc_queue.pop
        end

        private

        def create
            check_stale
            if(@workers.size < @max_workers)
                worker = Worker.new(self)
                @workers << worker
                return worker
            end
            return nil
        end

        def check_stale
            @workers.each do |worker|
                @workers.delete(worker) if worker.stale?
            end
        end

        def resize
            if(@workers.size > @max_workers)
                until(@workers.size <= @max_workers) do
                    @workers.each do |worker|
                        @workers.delete(worker) if worker.kill(0.1)
                    end
                end
            end
        end

        class Worker
            def initialize(pool)
                @timeout = 0
                @pool = pool
                @active = false
                @time = Time.now
                @thread = Thread.new do
                    run_block
                end
            end

            def timeout=(secs)
                raise Exceptions::InvalidValue.new('Timeout must be a positive integer or zero') unless secs.to_i >=0
                @timeout = secs.to_i
            end

            def last_run
                @time
            end

            def stale?
                !(['sleep', 'run'].include?(@thread.status))
            end

            def kill(timeout=0.01, force=false)
                slept = 0.0
                unless(force)
                    until(!@active || slept >= timeout) do
                        sleep(0.01)
                        slept += 0.01
                    end
                end
                @thread.kill unless @active
                return stale?
            end

            private

            def run_block
                loop do
                    begin
                        block = @pool.pending_tasks
                        @active = true
                        @time = Time.now
                        if(@timeout > 0)
                            begin
                                Timeout::timeout(@timeout) do
                                    block.call
                                end
                            rescue Timeout::Error => boom
                                Logger.log("Worker timed out processing block. (exceeded #{@timeout} seconds)")
                            end
                        else
                            block.call
                        end
                    rescue Object => boom
                        Logger.log("Worker caught an error while processing block: #{boom}")
                    ensure
                        @active = false
                    end
                end
            end
        end

    end
end