module ModSpox
    module Messages
        module Internal
            class TimerRemove
                # action to remove
                attr_reader :action
                # message identification
                attr_reader :ident
                # action:: action to remove from timer
                # Remove action from timer
                def initialize(action)
                    @action = action
                    @ident = rand(99999999)
                end
                
                # Message ID
                def id
                    @ident
                end
            end
        end
    end
end