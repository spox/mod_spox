class PoolConfig < ModSpox::Plugin

    def initialize(args)
        super
        group = Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'pool max workers(\s(\d+))?', :method => :max_workers, :group => group,
                :desc => 'Show/set max number of worker threads', :params => [:max])
        add_sig(:sig => 'pool min workers(\s(\d+))?', :method => :min_workers, :group => group,
                :desc => 'Show/set min number of worker threads', :params => [:min])
        add_sig(:sig => 'pool workers (\d+)-(\d+)', :method => :max_min, :group => group,
                :desc => 'Set max and min workers in pool', :params => [:min, :max])
        add_sig(:sig => 'pool worker timeout(\s(\d+))?', :method => :max_timeout, :group => group,
                :desc => 'Show/set max worker timeout', :params => [:max])
        add_sig(:sig => 'pool workers available', :method => :workers_available, :group => group,
                :desc => 'Show current number of workers in pool')
        add_sig(:sig => 'pool max idle(\s(\d+))?', :method => :max_idle, :group => group,
                :desc => 'Show/set max number of seconds workers can idle', :params => [:seconds])
        add_sig(:sig => 'pool workers active', :method => :workers_active, :group => group,
                :desc => 'Show number of workers currently active')
        add_sig(:sig => 'pool workers idle', :method => :workers_idle, :group => group,
                :desc => 'Show number of workers currently idle')
        stored = Config[:pool_workers_max]
        unless(stored.nil?)
            Pool.max_workers = stored
        end
        stored = Config[:pool_workers_min]
        unless(stored.nil?)
            Pool.min_workers = stored
        end
        stored = Config[:pool_timeout]
        unless(stored.nil?)
            Pool.max_exec_time = stored
        end
        stored = Config[:pool_clean]
        unless(stored.nil?)
            clean_pool
        end
    end

    def workers_active(m, pa)
        reply m.replyto, "Current number of active workers: #{Pool.workers_active}"
    end
    
    def workers_idle(m, pa)
        reply m.replyto, "Current number of idle workers: #{Pool.workers_idle}"
    end

    def max_min(message, params)
        max = params[:max].to_i
        min = params[:min].to_i
        if(max < min)
            reply message.replyto, '\2Error:\2 Minimum number of threads must be less than the maximum number of threads'
        else
            {'pool_workers_min' => min, 'pool_workers_max' => max}.each_pair do |key, value|
                config = Config.find_or_create(:name => key)
                config.value = value
                config.save
            end
            Pool.max_workers = max
            Pool.min_workers = min
            reply message.replyto, "Pool updated. Max workers: #{max} Min workers: #{min}"
        end
    end

    def min_workers(message, params)
        if(params[:min].nil?)
            reply message.replyto, "Minimum number of worker threads allowed in pool: #{Pool.min_workers}"
        else
            params[:min] = params[:min].strip.to_i
            if(params[:min] > 0)
                config = Config.find_or_create(:name => 'pool_workers_min')
                config.value = params[:min]
                config.save
                Pool.min_workers = params[:min]
                reply message.replyto, "\2Thread Pool Update:\2 Minimum number of worker threads updated to: #{params[:min]}"
            else
                reply message.replyto, "\2Error:\2 You must have at least one worker thread"
            end
        end
    end

    def max_workers(message, params)
        if(params[:max].nil?)
            reply message.replyto, "Maximum number of worker threads allowed in pool: #{Pool.max_workers}"
        else
            params[:max] = params[:max].strip.to_i
            if(params[:max] > 0)
                config = Config.find_or_create(:name => 'pool_workers_min')
                config.value = params[:max]
                config.save
                Pool.max_workers = params[:max]
                reply message.replyto, "\2Thread Pool Update:\2 Number of worker threads updated to: #{params[:max]}"
            else
                reply message.replyto, "\2Error:\2 You must have at least one worker thread"
            end
        end
    end

    def max_timeout(message, params)
        if(params[:max].nil?)
            reply message.replyto, "Maximum number of seconds threads allowed per task: #{Pool.max_exec_time == 0 ? 'no limit' : Pool.max_exec_time}"
        else
            params[:max] = params[:max].strip.to_i
            if(params[:max] >= 0)
                config = Config.find_or_create(:name => 'pool_timeout')
                config.value = params[:max]
                config.save
                Pool.max_exec_time = params[:max]
                reply message.replyto, "\2Thread Pool Update:\2 Worker processing timeout updated to: #{params[:max]} seconds"
            else
                reply message.replyto, "\2Error:\2 Threads are not able to finish executing before they start"
            end
        end
    end

    def workers_available(message, params)
        reply message.replyto, "Current number of worker threads in pool: #{Pool.workers}"
    end
    
    def max_idle(message, params)
        if(params[:seconds].nil?)
            idle = Config[:pool_clean]
            reply message.replyto, "Maximum number of seconds workers are allowed to idle: #{idle.nil? ? 'no limit' : idle}"
        else
            params[:seconds] = params[:seconds].strip.to_i
            if(params[:seconds] == 0)
                Config.filter(:name => 'pool_clean').destroy
                reply message.replyto, 'Worker threads are now allowed to idle without limit'
            elsif(params[:seconds] > 0)
                config = Config.find_or_create(:name => 'pool_clean')
                config.value = params[:seconds]
                config.save
                clean_pool
                reply message.replyto, "Worker threads are now allowed to idle for: #{params[:seconds]} seconds"
            else
                reply message.replyto, "\2Error:\ Workers are required to idle for at least one second"
            end
        end
    end

    def clean_pool
        config = Config[:pool_clean]
        return if config.nil? || config.to_i < 1
        Pool.stop_old_workers(config.to_i)
        @pipeline << Messages::Internal::TimerAdd.new(self, config.to_i, nil, true){ clean_pool }
    end

end