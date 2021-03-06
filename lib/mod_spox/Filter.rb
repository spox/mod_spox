module ModSpox
    class Filter
        # message type filter is applied to
        attr_reader :type
        def initialize(t)
            @type = t
        end

        # message:: Message from pipeline
        # Applies filters to message
        def filter(message)
            raise ArgumentError.new("Wrong type supplied (Expected: #{@type})") unless Helpers.type_of?(message, @type)
            return do_filter(message)
        end
        
        protected
        
        # message:: Message to be filtered
        # This is where the actual filtering takes place. This
        # is the method to overload!
        # NOTE: Messages can be filtered in any way. For a filter to
        # basically "throw away" a message, simply set the message to
        # nil and it will not be processed or added to the pipeline:
        # return nil
        def do_filter(message)
            raise Exceptions::NotImplemented.new
        end
    end
end