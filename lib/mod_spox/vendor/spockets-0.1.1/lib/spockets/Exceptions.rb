module Spockets
    
    class UnknownSocket < StandardError
        attr_reader :socket
        def initialize(s)
            @socket = s
        end
    end

    class AlreadyRunning < StandardError
    end
    
    class NotRunning < StandardError
    end

    class Resync < StandardError
    end
    
end