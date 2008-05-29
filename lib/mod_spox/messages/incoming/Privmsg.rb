require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Privmsg < Message
                
                # source of the message
                attr_reader :source
                # target of the message
                attr_reader :target
                # the message sent
                attr_reader :message
                def initialize(raw, source, target, message)
                    super(raw)
                    @source = source
                    @target = target
                    if(message =~ /^\001ACTION\s(.+)\001/)
                        @message = $1
                        @action = true
                    else
                        @message = message
                        @action = false
                    end
                    botnick = Models::Nick.filter(:botnick => true).first
                    if(botnick)
                        @addressed = @message =~ /^#{botnick.nick}/i
                    else
                        @addressed = false
                    end
                end
                
                # Is message addressing the bot
                def addressed?
                    return @addressed || is_private?
                end
                
                # Is this is private message
                def is_private?
                    return @target.is_a?(Models::Nick)
                end
                
                # Is this a public message
                def is_public?
                    return @target.is_a?(Models::Channel)
                end
                
                # Does the message contain colors
                def is_colored?
                    return @message =~ /\cC\d\d?(?:,\d\d?)?/
                end
                
                # Message with coloring stripped
                def message_nocolor
                    return @message.gsub(/\cC\d\d?(?:,\d\d?)?/, '')
                end
                
                # Is this message an action message
                def is_action?
                    @action
                end
                
                # Convinence method for replying to the correct place
                def replyto
                    return @source if is_private?
                    return @target if is_public?
                end
            
            end
        end
    end
end