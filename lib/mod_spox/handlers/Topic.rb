module ModSpox
    module Handlers
        class Topic < Handler
            def initialize(handlers)
                handlers[RPL_TOPIC] = self
                handlers[RPL_NOTOPIC] = self
                handlers[RPL_TOPICINFO] = self
                @topics = Hash.new
            end
            def process(string)
                if(string =~ /#{RPL_TOPIC}.+?(\S+)\s:(.+)$/)
                    channel = find_model($1)
                    return Messages::Incoming::Topic.new(string, channel, $2)
                elsif(string =~ /#{RPL_NOTOPIC}.+?(\S+)\s:/)
                    channel = find_model($1)
                    return Messages::Incoming::Topic.new(string, channel, nil)
                elsif(string =~ /#{RPL_TOPICINFO}\s\S+\s(\S+)\s(\S+)\s(.+)$/)
                    channel = find_model($1)
                    nick = find_model($1)
                    time = Time.at($3.to_i)
                    return Messages::Incoming::TopicInfo.new(string, channel, nick, time)
                else
                    Logger.log('Failed to parse TOPIC type string')
                end                    
            end
        end
    end
end
        