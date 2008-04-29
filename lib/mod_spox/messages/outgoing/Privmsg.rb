module ModSpox
    module Messages
        module Outgoing
            class Privmsg
                # target for the message
                attr_reader :target
                # the message
                attr_reader :message
                # message is an action
                attr_reader :action
                # target:: target for the message
                # message:: message to be sent
                # Send a message to user or channel
                def initialize(target, message, action=false)
                    @target = target
                    @message = message
                    @action = action
                end
                
                # is message an action
                def is_action?
                    return action
                end
            end
        end
    end
end