require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Notice < Handler
            def initialize(handlers)
                handlers[:NOTICE] = self
            end
            
            def process(string)
                if(string =~ /:(\S+)\sNOTICE\s(\S+)\s:(.+)$/)
                    base_source = $1
                    target = $2
                    message = $3
                    if(base_source =~ /\!/)
                        source = find_model(base_source.gsub(/!.+$/, ''))
                        if(base_source =~ /!(.+)@(.+)$/)
                            source.username == $1
                            source.address = $2
                            source.source = base_source
                            source.save_changes
                        end
                        target = find_model(target)
                    else
                        source = base_source
                    end
                    return Messages::Incoming::Notice.new(string, source, target, message)
                else
                    Logger.log('Failed to match NOTICE message')
                    return nil
                end
            end
        end
    end
end