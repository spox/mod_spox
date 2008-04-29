module ModSpox
    module Handlers
        class Privmsg < Handler
            def initialize(handlers)
                handlers[:PRIVMSG] = self
            end
            
            def process(string)
                if(string =~ /^:(\S+)\sPRIVMSG\s(\S+)\s:(.+)$/)
                    message = $3
                    target = find_model($2)
                    base_source = $1
                    source = find_model(base_source.gsub(/!.+$/, ''))
                    if(base_source =~ /!(.+)@(.+)$/)
                        source.username = $1
                        source.address = $2
                        source.source = base_source
                        source.save
                    end
                    Models::NickChannel.find_or_create(:channel_id => target.pk, :nick_id => source.pk) if target.is_a?(ModSpox::Models::Channel)
                    return Messages::Incoming::Privmsg.new(string, source, target, message)
                else
                    Logger.log('Failed to match PRIVMSG message')
                end
            end
        end
    end
end