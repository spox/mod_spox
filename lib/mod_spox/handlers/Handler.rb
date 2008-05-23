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

Dir.new(File.dirname(__FILE__)).each do |file|
    require File.dirname(__FILE__) + '/' + file if file =~ /\.rb$/
end