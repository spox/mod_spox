require 'mod_spox/handlers/Handler'
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
                        source.save_changes
                    end
                    source.add_channel(target) if target.is_a?(Models::Channel)
                    return Messages::Incoming::Privmsg.new(string, source, target, message)
                else
                    Logger.warn('Failed to match PRIVMSG message')
                    return nil
                end
            end
        end
    end
end