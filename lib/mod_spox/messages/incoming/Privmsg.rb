require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Privmsg < Message

                # source of the message
                attr_reader :source
                # target of the message
                attr_reader :target
                # message is CTCP
                attr_reader :ctcp
                # message CTCP type
                attr_reader :ctcp_type
                def initialize(raw, source, target, message)
                    super(raw)
                    @source = source
                    @target = target
                    @ctcp = false
                    @ctcp_type = nil
                    @action = false
                    if(@raw_content =~ /\x01(\S+)\s(.+)\x01/)
                        @ctcp = true
                        @ctcp_type = $1
                        @message = $2
                        @action = @ctcp_type.downcase == 'action'
                    else
                        @message = message
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
                    return !is_public?
                end

                # Is this a DCC message
                def is_dcc?
                    return @target.is_a?(String)
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
                    return @message.gsub(/\cC\d\d?(?:,\d\d?)?/, '').tr("\x00-\x1f", '')
                end

                # the message sent
                def message(color=false)
                    return color ? @message : message_nocolor
                end

                # Is this message an action message
                def is_action?
                    @action
                end

                def is_ctcp?
                    @ctcp
                end

                # Convinence method for replying to the correct place
                def replyto
                    return is_public? || is_dcc? ? @target : @source
                end

            end
        end
    end
end