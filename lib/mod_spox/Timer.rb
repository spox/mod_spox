['mod_spox/Logger',
 'mod_spox/Pipeline',
 'mod_spox/Pool',
 'mod_spox/Action',
 'mod_spox/Exceptions',
 'mod_spox/Monitors'].each{|f|require f}

module ModSpox

    class Timer

        # pipeline:: message pipeline
        # Create a new Timer
        def initialize(pipeline)
            @pipeline = pipeline
            @timers = Array.new
            @monitor = Monitors::Timer.new
            @thread = nil
            @stop_timer = false
            @owners = {}
            @owners_lock = Mutex.new
            @add_lock = Monitors::Boolean.new
            @adding = false
            {:Internal_TimerAdd => :add_message,
             :Internal_TimerRemove => :remove_message,
             :Internal_TimerClear => :clear}.each_pair do |type,method|
                @pipeline.hook(self, method, type)
            end
        end

        # Wakes the timer up early
        def wakeup
            Logger.info("Timer has been explicitly told to wakeup")
            @monitor.wakeup unless @thread.nil?
        end

        # message:: TimerAdd message
        # Add a recurring code block
        def add_message(message)
            Logger.info("New block is being added to the timer")
            action = nil
            action = add(message.period, message.once, message.data, &message.block)
            @owners[message.requester.name.to_sym] = [] unless @owners.has_key?(message.requester.name.to_sym)
            @owners[message.requester.name.to_sym] << action
            begin
                @pipeline << Messages::Internal::TimerResponse.new(message.requester, action, true, message.id)
                Logger.info("New block was successfully added to the timer")
            rescue Object => boom
                Logger.warn("Failed to add block to timer: #{boom}")
                @pipeline << Messages::Internal::TimerResponse.new(message.requester, action, false, message.id)
            end
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
            @adding = true
            wakeup
            @add_lock.wait
            @timers << action
            @adding = false
            @add_lock.wakeup
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
            raise Exceptions::AlreadyRunning.new('Timer is already running') unless @thread.nil?
            @thread = Thread.new{
                until @stop_timer do
                    to_sleep = nil
                    @timers.each do |a|
                        to_sleep = a.remaining if to_sleep.nil?
                        to_sleep = a.remaining if !a.remaining.nil? && a.remaining < to_sleep
                    end
                    Logger.info("Timer is set to sleep for #{to_sleep.nil? ? 'forever' : "#{to_sleep} seconds"}")
                    actual_sleep = @monitor.wait(to_sleep)
                    tick(actual_sleep)
                    Logger.info("Timer was set to sleep for #{to_sleep.nil? ? 'forever' : "#{to_sleep} seconds"}. Actual sleep time: #{actual_sleep} seconds")
                    @add_lock.wakeup
                    @add_lock.wait while @adding
                end
            }
        end

        # Stops the timer
        def stop
            raise Exceptions::NotRunning.new('Timer is not running') if @thread.nil?
            @stop_timer = true
            wakeup
            @thread.join
        end

        # Clears all actions in the timer's queue
        def clear(message=nil)
            if(message.nil? || message.plugin.nil?)
                @timers.clear
                @owners.clear
            else
                @owners_lock.synchronize do
                    if(@owners.has_key?(message.plugin))
                        @owners[message.plugin].each do |action|
                            remove(action)
                        end
                    end
                end
            end
        end

        private

        # time_passed:: time passed since last tick
        # Decrements all Actions the given amount of time
        def tick(time_passed)
            ready = []
            for action in @timers do
                action.tick(time_passed)
                if(action.due?)
                    ready << action.schedule
                end
            end
            ready.each{|action| Pool << lambda{ processor(action) }}
        end

        # Process the actions
        def processor(action)
            begin
                action.run
                remove(action) if action.is_complete?
            rescue Object => boom
                Logger.warn("Timer block generated an exception: #{boom}\n#{boom.backtrace.join("\n")}")
            end
        end

    end

end