require 'mod_spox/rfc2812'
require 'mod_spox/Helpers'
module ModSpox
    module Handlers
    
        class Handler

            # handlers:: array of handlers
            # initialize handler and add self to available
            # handlers
            def initialize(handlers)
                raise Exceptions::NotImplemented.new('Method has not been implemented')
            end

            # data:: string of data
            # Process the string and create the proper object
            def process(data)
                raise Exceptions::NotImplemented.new('Method has not been implemented')
            end
            
            # data:: any expected data
            # Preprocessing allows for actions to be taken
            # while messages are still in a synchronized state
            def preprocess(data)
            end
            
            protected

            # deprecated. here basically so old handlers
            # don't break
            def find_model(string)
                Helpers.find_model(string)
            end
        
        end
        
    end
end

Dir.new(File.dirname(__FILE__)).each do |file|
    require File.dirname(__FILE__) + '/' + file if file =~ /\.rb$/
end