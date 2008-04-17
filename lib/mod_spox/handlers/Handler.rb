module ModSpox
    module Handlers
    
        class Handler
        
            def process(data)
                raise Exceptions::NotImplemented.new('Method has not been implemented')
            end
            
            protected
            
            def find_model(string)
                if(string =~ /^[A-Za-z\|\\\{\}\[\]\^\`~\_\-]+[A-Za-z0-9\|\\\{\}\[\]\^\`~\_\-]*$/)
                    Logger.log("Model: #{string} -> Nick")
                    return Models::Nick.find_or_create(:nick => string)
                elsif(string =~ /^[&#+!]/)
                    Logger.log("Model: #{string} -> Channel")
                    return Models::Channel.find_or_create(:name => string)
                elsif(model = Models::Server.filter(:host => string, :connected => true).first)
                    Logger.log("Model: #{string} -> Server")
                    return model
                else
                    Logger.log("FAIL Model: #{string} -> No match")
                    return string
                end
            end
        
        end
        
    end
end