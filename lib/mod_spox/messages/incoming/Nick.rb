require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Nick < Message
            
                # previous nick
                attr_reader :original_nick
                # new nick
                attr_reader :new_nick
                
                ## make sure old_nick is the source here
                ## in the processor breaking the raw message
                
                # old_nick:: this should be the source
                # new_nick:: this should be the target
                def initialize(raw, old_nick, new_nick)
                    super(raw)
                    @original_nick = @source_nick
                    @new_nick = @target
                end
            
            end
        end
    end
end