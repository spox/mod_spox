module ModSpox
    class Filter
        # message:: ModSpox::Message type
        # Applies filters to message
        def filter(message)
            raise Exceptions::NotImplemented.new
        end
    end
end