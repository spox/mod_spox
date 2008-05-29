require 'mod_spox/messages/internal/Response'
module ModSpox
    module Messages
        module Internal
            class TimerResponse < Response
                # action from timer
                attr_reader :action
                # response to message with this ID
                attr_reader :ident
                # object:: object to send response to
                # action:: action removed from timer
                # Notification that action has been removed
                def initialize(object, action, added, id)
                    super(object)
                    @action = action
                    @added = added
                    @ident = id
                end
                # Action was added to timer
                def action_added?
                    return @added
                end
                # Action was removed from timer
                def action_removed?
                    return !@added
                end
                # ID of message this response is for
                def id
                    @ident
                end
            end
        end
    end
end