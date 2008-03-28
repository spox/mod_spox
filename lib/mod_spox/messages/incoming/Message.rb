module ModSpox
    module Messages
        module Incoming
        
            class Message
                
                # raw string from server
                attr_reader :raw_content
                
                # time of message creation
                attr_reader :time
                
                def initialize(content)
                    @raw_content = content
                    @time = Time.now
                end
        
            end
        
        end
    end
end