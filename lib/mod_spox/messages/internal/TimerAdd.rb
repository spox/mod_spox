module ModSpox
    module Messages
        module Internal
            class TimerAdd < Request
                # code block to execute
                attr_reader :block
                # data to supply to block
                attr_reader :data
                # interval between executions
                attr_reader :period
                # only execute block once
                attr_reader :once
                # period:: interval between executions
                # once:: only run block once
                # block:: code block
                # Add repeating event to timer
                def initialize(object, period, data=nil, once=false, &block)
                    super(object)
                    @data = data
                    @period = period
                    @once = once
                    @block = block
                end
            end
        end
    end
end