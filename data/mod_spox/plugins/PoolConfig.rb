class PoolConfig < ModSpox::Plugin
    include Models
    def initialize(args)
        super
        group = Group.find_or_create(:name => 'admin')
        Signature.find_or_create(:signature => 'pool max workers (\d+)', :plugin => name, :method => 'set_max_workers',
            :group_id => group.pk, :description => 'Set max number of worker threads').params = [:max]
        Signature.find_or_create(:signature => 'pool timeout (\d+)', :plugin => name, :method => 'set_max_timeout',
            :group_id => group.pk, :description => 'Set max timeout for worker threads').params = [:max]
        Signature.find_or_create(:signature => 'pool workers available', :plugin => name, :method => 'workers_available',
            :group_id => group.pk, :description => 'Show number of workers in pool')
        Signature.find_or_create(:signature => 'pool workers max', :plugin => name, :method => 'workers_max',
            :group_id => group.pk, :description => 'Show maxiumum number of worker threads')
        Signature.find_or_create(:signature => 'pool timeout', :plugin => name, :method => 'show_timeout',
            :group_id => group.pk, :description => 'Show maximum worker execution time')
        Signature.find_or_create(:signature => 'pool clean (\d+)', :plugin => name, :method => 'set_pool_clean',
            :group_id => group.pk, :description => 'Set how many seconds workers are allowed to idle').params = [:seconds]
        Signature.find_or_create(:signature => 'pool workers idle', :plugin => name, :method => 'show_worker_idle',
            :group_id => group.pk, :description => 'Show how many seconds workers are allowed to idle')
        stored = Config[:pool_workers]
        unless(stored.nil?)
            Pool.max_workers = stored
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

    def set_max_workers(message, params)
        if(params[:max].to_i > 0)
            config = Config.find_or_create(:name => 'pool_workers')
            config.value = params[:max].to_i
            config.save
            Pool.max_workers = params[:max].to_i
            reply message.replyto, "\2Thread Pool Update:\2 Number of worker threads updated to: #{params[:max]}"
        else
            reply message.replyto, "\2Error:\2 You must have at least one worker thread"
        end
    end

    def set_max_timeout(message, params)
        if(params[:max].to_i >= 0)
            config = Config.find_or_create(:name => 'pool_timeout')
            config.value = params[:max].to_i
            config.save
            Pool.max_exec_time = params[:max].to_i
            reply message.replyto, "\2Thread Pool Update:\2 Worker processing timeout updated to: #{params[:max]} seconds"
        else
            reply message.replyto, "\2Error:\2 Threads are not able to finish executing before they start"
        end
    end

    def workers_available(message, params)
        reply message.replyto, "Current number of worker threads in pool: #{Pool.workers}"
    end

    def workers_max(message, params)
        reply message.replyto, "Maximum number of worker threads allowed in pool: #{Pool.max_workers}"
    end

    def show_timeout(message, params)
        reply message.replyto, "Maximum number of seconds threads allowed per task: #{Pool.max_exec_time == 0 ? 'no limit' : Pool.max_exec_time}"
    end

    def show_worker_idle(message, params)
        idle = Config[:pool_clean]
        reply message.replyto, "Maximum number of seconds workers are allowed to idle: #{idle.nil? ? 'no limit' : idle}"
    end

    def set_pool_clean(message, params)
        if(params[:seconds].to_i == 0)
            Config.filter(:name => 'pool_clean').destroy
            reply message.replyto, 'Worker threads are now allowed to idle without limit'
        elsif(params[:seconds].to_i > 0)
            config = Config.find_or_create(:name => 'pool_clean')
            config.value = params[:seconds]
            config.save
            clean_pool
            reply message.replyto, "Worker threads are now allowed to idle for: #{params[:seconds]} seconds"
        else
            reply message.replyto, "\2Error:\ Workers are required to idle for at least one second"
        end
    end

    def clean_pool
        config = Config[:pool_clean]
        return if config.nil?
        Pool.stop_old_workers(config.to_i)
        @pipeline << Messages::Internal::TimerAdd.new(self, config.to_i, nil, true){ clean_pool }
    end

end