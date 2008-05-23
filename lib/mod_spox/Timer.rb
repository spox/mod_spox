['mod_spox/Logger',
 'mod_spox/Pipeline',
 'mod_spox/Pool',
 'mod_spox/Action',
 'mod_spox/Exceptions',
 'mod_spox/Monitors'].each{|f|require f}

module ModSpox

    class Timer < Pool
    
        # pipeline:: message pipeline
        # Create a new Timer
        def initialize(pipeline)
            super()
            @pipeline = pipeline
            @timers = Array.new
            Logger.log("Created queue: #{@queue} in timer", 10)
            @monitor = Monitors::Timer.new
            @thread = nil
            @stop_timer = false
            {:Internal_TimerAdd => :add_message,
             :Internal_TimerRemove => :remove_message}.each_pair{|type,method|
                @pipeline.hook(self, method, type)
            }
            start_pool
        end
        
        # Wakes the timer up early
        def wakeup
            Logger.log("Timer has been explicitly told to wakeup", 15)
            @monitor.wakeup unless @thread.nil?
        end
        
        # message:: TimerAdd message
        # Add a recurring code block
        def add_message(message)
            Logger.log("New block is being added to the timer", 15)
            action = add(message.period, message.once, message.data, &message.block)
            begin
                @pipeline << Messages::Internal::TimerResponse.new(message.requester, action, true, message.id)
                Logger.log("New block was successfully added to the timer", 15)
            rescue Object => boom
                Logger.log("Failed to add block to timer: #{boom}", 10)
                @pipeline << Messages::Internal::TimerResponse.new(message.requester, action, false, message.id)
            end
        end
        
        # message:: TimerRemove message
        # Remove an action from the timer
        def remove_message(message)
            remove(message.action)
            Logger.log("Action has been removed from the Timer", 15)
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
            wakeup
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
                    Logger.log("Timer is set to sleep for #{to_sleep.nil? ? 'forever' : "#{to_sleep} seconds"}", 15)
                    actual_sleep = @monitor.wait(to_sleep)
                    tick(actual_sleep)
                    Logger.log("Timer was set to sleep for #{to_sleep.nil? ? 'forever' : "#{to_sleep} seconds"} seconds. Actual sleep time: #{actual_sleep} seconds", 15)
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
        def clear
            @queue.clear
            @timers.clear
        end
        
        private
        
        # time_passed:: time passed since last tick
        # Decrements all Actions the given amount of time
        def tick(time_passed)
            for action in @timers do
                action.tick(time_passed)
                if(action.due?)
                    @queue << action.schedule
                end
            end
        end
        
        # Process the actions
        def processor
            action = @queue.pop
            begin
                action.run
                remove(action) if action.is_complete?
            rescue Object => boom
                Logger.log("Timer block generated an exception: #{boom}\n#{boom.backtrace.join("\n")}", 5)
            end
        end
    
    end
    
end