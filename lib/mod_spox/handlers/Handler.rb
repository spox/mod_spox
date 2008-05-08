module ModSpox
    module Handlers
    
        class Handler
        
            def process(data)
                raise Exceptions::NotImplemented.new('Method has not been implemented')
            end
            
            protected
            
            def find_model(string)
                Helpers.find_model(string)
            end
        
        end
        
    end
end