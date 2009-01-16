['mod_spox/Logger',
 'mod_spox/Pipeline',
 'mod_spox/Pool',
 'mod_spox/Action',
 'mod_spox/Exceptions'].each{|f|require f}

module ModSpox

    class Timer

        # pipeline:: message pipeline
        # Create a new Timer
        def initialize(pipeline)
            @pipeline = pipeline
            @timers = Array.new
            @timer_thread = nil
            @stop_timer = false
            @awake_lock = Mutex.new
            @add_lock = Mutex.new
            @new_actions = Queue.new
            {:Internal_TimerAdd => :add_message,
             :Internal_TimerRemove => :remove_message,
             :Internal_TimerClear => :clear}.each_pair do |type,method|
                @pipeline.hook(self, method, type)
            end
        end

        # Wakes the timer up early
        def wakeup
            @awake_lock.synchronize do
                if(@timer_thread.status == 'sleep')
                    Logger.info('Timer has been explicitly told to wakeup')
                    @timer_thread.wakeup
                end
            end
        end

        # message:: TimerAdd message
        # Add a recurring code block
        def add_message(message)
            Logger.info("New block is being added to the timer")
            action = nil
            @new_actions << {:period => message.period, :once => message.once, :data => message.data,
                             :block => message.block, :requester => message.requester, :m_id => message.id}
            wakeup
        end

        # message:: TimerRemove message
        # Remove an action from the timer
        def remove_message(message)
            remove(message.action)
            Logger.info("Action has been removed from the Timer")
            @pipeline << Messages::Internal::TimerResponse.new(nil, message.action, false, message.id)
        end

        # period:: seconds between running action
        # once:: only run action once
        # data:: data to be available
        # &func:: data block to run
        # Adds a new action to the timer
        def add(period, once=false, data=nil, &func)
            action = Action.new(self, period, data, once, &func)
            @timers << action
            return action
        end

        # action:: Action to add to timer's queue
        # Adds a new action to the timer
        def add_action(action)
            raise Exceptions::InvalidType.new('An Action object must be supplied') unless action.is_a?(Action)
            @timers << action
            wakeup
        end

        # action:: Action to remove from timer's queue
        # Removes and action from the timer
        def remove(action)
            raise Exceptions::InvalidType.new('An Action object must be supplied') unless action.is_a?(Action)
            @timers.delete(action)
            wakeup
        end

        # Starts the timer
        def start
            raise Exceptions::AlreadyRunning.new('Timer is already running') unless @timer_thread.nil?
            @timer_thread = Thread.new do
            begin
                until @stop_timer do
                    to_sleep = get_min_sleep
                    Logger.info("Timer is set to sleep for #{to_sleep.nil? ? 'forever' : "#{to_sleep} seconds"}")
                    if((to_sleep.nil? || to_sleep > 0) && @new_actions.empty?)
                        actual_sleep = to_sleep.nil? ? sleep : sleep(to_sleep)
                    else
                        actual_sleep = 0
                    end
                    Logger.info("Timer was set to sleep for #{to_sleep.nil? ? 'forever' : "#{to_sleep} seconds"}. Actual sleep: #{actual_sleep} seconds")
                    tick(actual_sleep)
                    add_waiting_actions
                end
            rescue Object => boom
                Logger.warn("Timer error encountered: #{boom}")
            end
            Logger.warn("Timer has completed running.")
            end
        end

        # Stops the timer
        def stop
            raise Exceptions::NotRunning.new('Timer is not running') if @timer_thread.nil?
            @stop_timer = true
            wakeup
            @timer_thread.join
        end

        # Clears all actions in the timer's queue
        def clear(message=nil)
            if(message.nil? || message.plugin.nil?)
                @timers.clear
                @new_actions.clear
                wakeup
            else
                @timers.each{ |action| @timers.delete(action) if action.owner == message.plugin}
                wakeup
            end
        end

        private

        def get_min_sleep
            min = @timers.map{|t| t.remaining}.sort[0]
            unless(min.nil? || min > 0)
                @timers.each{|t| @timers.delete(t) if t.remaining == 0} # kill stuck actions
                min = get_min_sleep
            end
            Logger.info("Total number of actions in timer: #{@timers.size}")
            Logger.info("Actions belong to: #{@timers.map{|a| a.owner}.join(', ')}")
            return min
        end

        def add_waiting_actions
            until(@new_actions.empty?) do
                a = @new_actions.pop
                action = add(a[:period], a[:once], a[:data], &a[:block])
                action.owner = a[:requester]
                begin
                    @pipeline << Messages::Internal::TimerResponse.new(a[:requester], action, true, a[:m_id])
                    Logger.info("New block was successfully added to the timer")
                rescue Object => boom
                    Logger.warn("Failed to add block to timer: #{boom}")
                    @pipeline << Messages::Internal::TimerResponse.new(a[:requester], action, false, a[:m_id])
                end
            end
        end

        # time_passed:: time passed since last tick
        # Decrements all Actions the given amount of time
        def tick(time_passed)
            for action in @timers do
                action.tick(time_passed)
                if(action.due?)
                    remove(action) if action.is_complete?
                    block = action.schedule
                    Pool << lambda{processor(block)}
                end
            end
        end

        # Process the actions
        def processor(action)
            begin
                action.run
            rescue Object => boom
                Logger.warn("Timer block generated an exception: #{boom}\n#{boom.backtrace.join("\n")}")
            end
        end

    end

end