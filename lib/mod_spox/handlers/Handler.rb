require 'mod_spox/rfc2812'
module ModSpox
    module Handlers
    
        class Handler
        
            def initialize(handlers)
            end
        
            def process(data)
                raise Exceptions::NotImplemented.new('Method has not been implemented')
            end
            
            # data:: any expected data
            # Preprocessing allows for actions to be taken
            # while messages are still in a synchronized state
            def preprocess(data)
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