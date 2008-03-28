module ModSpox

    class Action
    
        # timer:: Timer the action is being added to
        # period:: number of seconds between runs
        # data:: data to be available for the action
        # once:: only run the action once
        # &func:: block of code to run
        # Create a new Action
        def initialize(timer, period, data=nil, once=false, &func)
            @period = period.to_f
            @func = func
            @data = data
            @once = once
            @due = false
            @timer = timer
            @completed = false
            @wait_remaining = @period
        end
        
        # amount:: number of seconds passed
        # Decrement wait time by given number of seconds
        def tick(amount)
            @wait_remaining = @wait_remaining - amount
        end
        
        # Returns true if action is due to run
        def due?
            @wait_remaining <= 0
        end
        
        # Returns the remaining number of seconds
        def remaining
            @wait_remaining <= 0 ? 0 : @wait_remaining
        end
        
        # new_time:: number of seconds between runs
        # Resets the wait time between runs
        def reset_period(new_time)
            @period = new_time.to_f
            @wait_remaining = @period
            @timer.wakeup
        end
        
        # Returns if the Action has completed all its runs
        def is_complete?
            @completed
        end
        
        # Used for scheduling with Timer. Resets its internal
        # timer and returns itself
        def schedule
            @wait_remaining = @period
            return self
        end
        
        # Runs the function block of the action
        def run
            begin
                unless @data.nil?
                    @func.call(@data)
                else
                    @func.call
                end
            rescue Object => boom
                Logger.log("Action generated an exception during run: #{boom}\n#{boom.backtrace.join("\n")}", 10)
            end
            @completed = true if @once
        end
    end

end
