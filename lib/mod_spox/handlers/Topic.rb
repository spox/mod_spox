require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Topic'
require 'mod_spox/messages/incoming/TopicInfo'
module ModSpox
    module Handlers
        class Topic < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_TOPIC][:value]] = self
                handlers[RFC[:RPL_NOTOPIC][:value]] = self
                handlers[RFC[:RPL_TOPICINFO][:value]] = self
                @topics = Hash.new
            end
            
#:irc.host 332 spox #mod_spox : the topic is here
#:irc.host 333 spox #mod_spox spox 1232126516
            
            def process(string)
                if(string =~ /#{RFC[:RPL_TOPIC][:value]}.+?(\S+)\s:(.+)$/)
                    channel = find_model($1)
                    channel.update(:topic => $2)
                    return Messages::Incoming::Topic.new(string, channel, $2)
                elsif(string =~ /#{RFC[:RPL_NOTOPIC][:value]}.+?(\S+)\s:/)
                    channel = find_model($1)
                    return Messages::Incoming::Topic.new(string, channel, nil)
                elsif(string =~ /#{RFC[:RPL_TOPICINFO][:value]}\s\S+\s(\S+)\s(\S+)\s(.+)$/)
                    channel = find_model($1)
                    nick = find_model($1)
                    time = Time.at($3.to_i)
                    return Messages::Incoming::TopicInfo.new(string, channel, nick, time)
                else
                    Logger.warn('Failed to parse TOPIC type string')
                    return nil
                end                    
            end
        end
    end
end
        