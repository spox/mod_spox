module ModSpox
    module Messages
        module Internal
            class TimerRemove
                # action to remove
                attr_reader :action
                # action:: action to remove from timer
                # Remove action from timer
                def initialize(action)
                    @action = action
                end
            end
        end
    end
end