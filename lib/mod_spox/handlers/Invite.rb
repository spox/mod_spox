module ModSpox
    module Handlers
        class Invite < Handler
            def initialize(handlers)
                handlers[:INVITE] = self
            end
            def process(string)
                if(string =~ /^(.+?)!.*?INVITE\s(\S+)\s(.+)$/)
                    source = find_model($1)
                    target = find_model($2)
                    channel = find_model($3)
                    return Messages::Incoming::Invite(string, source, target, channel)
                else
                    Logger.log('Failed to parse INVITE message')
                end
            end
        end
    end
end