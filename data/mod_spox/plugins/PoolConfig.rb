class PoolConfig < ModSpox::Plugin

    def initialize(args)
        super
        group = Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'pool max workers(\s(\d+))?', :method => :max_workers, :group => group,
                :desc => 'Show/set max number of worker threads', :params => [:max])
        add_sig(:sig => 'pool worker timeout(\s(\d+))?', :method => :max_timeout, :group => group,
                :desc => 'Show/set max worker timeout', :params => [:max])
        add_sig(:sig => 'pool workers total', :method => :workers_total, :group => group,
                :desc => 'Show current number of workers in pool')
    end

    def max_workers(message, params)
        if(params[:max].nil?)
            reply message.replyto, "Maximum number of worker threads allowed in pool: #{Pool.workers_max}"
        else
            params[:max] = params[:max].strip.to_i
            if(params[:max] > 0)
                config = Config.find_or_create(:name => 'pool_workers_min')
                config.value = params[:max]
                config.save
                Pool.workers_max = params[:max]
                reply message.replyto, "\2Thread Pool Update:\2 Number of worker threads updated to: #{params[:max]}"
            else
                reply message.replyto, "\2Error:\2 You must have at least one worker thread"
            end
        end
    end

    def max_timeout(message, params)
        if(params[:max].nil?)
            reply message.replyto, "Maximum number of seconds threads allowed per task: #{Pool.worker_timeout == 0 ? 'no limit' : Pool.worker_timeout}"
        else
            params[:max] = params[:max].strip.to_i
            if(params[:max] >= 0)
                config = Config.find_or_create(:name => 'pool_timeout')
                config.value = params[:max]
                config.save
                Pool.worker_timeout = params[:max]
                reply message.replyto, "\2Thread Pool Update:\2 Worker processing timeout updated to: #{params[:max]} seconds"
            else
                reply message.replyto, "\2Error:\2 Threads are not able to finish executing before they start"
            end
        end
    end

    def workers_total(message, params)
        reply message.replyto, "Current number of worker threads in pool: #{Pool.workers}"
    end

end