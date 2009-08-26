['mod_spox/Logger',
 'mod_spox/Pipeline',
 'mod_spox/messages/internal/TimerResponse'].each{|f|require f}

module ModSpox

    class Timer

        # timer:: ActionTimer to use
        # pipeline:: Message pipeline
        # Creates a timer handler for interactions
        # with the ActionTimer
        def initialize(timer, pipeline)
            @pipeline = pipeline
            @timer = timer
            {ModSpox::Messages::Internal::TimerAdd => :add_message,
             ModSpox::Messages::Internal::TimerRemove => :remove_message,
             ModSpox::Messages::Internal::TimerClear => :clear}.each_pair do |type,method|
                @pipeline.hook(self, method, type)
            end
        end

        # message:: TimerAdd message
        # Add a recurring code block
        def add_message(message)
            Logger.info("New block is being added to the timer")
            begin
                action = @timer.add(message.period, message.once, message.data, message.requester, &message.block)
                @pipeline << Messages::Internal::TimerResponse.new(message.requester, action, true, message.id)
            rescue Object => boom
                Logger.error("Failed to add new block to timer: #{boom}")
                @pipeline << Messages::Internal::TimerResponse.new(message.requester, nil, false, message.id)
            end
        end

        # message:: TimerRemove message
        # Remove an action from the timer
        def remove_message(message)
            @timer.remove(message.action)
            Logger.info("Action has been removed from the Timer")
            @pipeline << Messages::Internal::TimerResponse.new(nil, message.action, false, message.id)
        end

        # Clears all actions in the timer's queue
        def clear(message=nil)
            if(message.nil? || message.plugin.nil?)
                @timer.clear
            else
                @timer.clear(message.plugin)
            end
        end
        
        # stop the timer
        def stop
            @timer.stop
        end

    end

end