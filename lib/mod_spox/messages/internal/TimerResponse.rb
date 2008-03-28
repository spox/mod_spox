module ModSpox
    module Messages
        module Internal
            class TimerResponse < Response
                # action from timer
                attr_reader :action
                # object:: object to send response to
                # action:: action removed from timer
                # Notification that action has been removed
                def initialize(object, action, added)
                    super(object)
                    @action = action
                    @added = added
                end
                # Action was added to timer
                def action_added?
                    return @added
                end
                # Action was removed from timer
                def action_removed?
                    return !@added
                end
            end
        end
    end
end