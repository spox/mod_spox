module ModSpox
    module Messages
        module Outgoing
            class Privmsg
                # target for the message
                attr_reader :target
                # the message
                attr_reader :message
                # type of CTCP message
                attr_reader :ctcp_type
                # target:: target for the message
                # message:: message to be sent
                # Send a message to user or channel. Setting action to true
                # is a shortcut to setting ctcp parameters. The action parameter
                # will override the ctcp parameters if all are set
                def initialize(target, message, action=false, ctcp=false, ctcp_type=nil)
                    @target = target
                    @message = message
                    @action = action
                    @ctcp = ctcp
                    @ctcp_type = ctcp_type.upcase unless ctcp_type.nil?
                    if(@action)
                        @ctcp = true
                        @ctcp_type = 'ACTION'
                    end
                    if(!@action && !@ctcp_type.nil?)
                        @action = true if @ctcp_type == 'ACTION'
                    end
                end
                
                # is message an action
                def is_action?
                    return @action
                end
                
                # is message CTCP
                def is_ctcp?
                    return @ctcp
                end
            end
        end
    end
end