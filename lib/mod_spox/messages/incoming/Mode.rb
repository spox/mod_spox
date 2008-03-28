module ModSpox
    module Messages
        module Incoming
            class Mode < Message
                
                # mode string (will be two or more characters matching: /^[+\-][A-Za-z]+$/)
                attr_reader :mode
                
                # mode channel (nil if target is nick (basically modes for the bot))
                attr_reader :channel
                
                # nick mode is applied to (nil if mode change is for channel only)
                # if multiple modes are applied to multiple nicks, this will be
                # an array holding the nicks in order the mode string was applied
                attr_reader :target
                
                # nick that applied the mode change
                attr_reader :source
                
                def initialize(raw, mode, source, target, channel)
                    super(raw)
                    @mode = mode
                    @channel = channel
                    @source = source
                    @target = target
                end
                
                # If mode is for a nick
                def for_nick?
                    return @channel.nil?
                end
                
                # If mode is for a channel
                def for_channel?
                    return @target.nil?
                end
                
            end
        end
    end
end