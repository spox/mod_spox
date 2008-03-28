module ModSpox
    module Messages
        module Internal
            class ConnectionFailed
                # server attempted 
                attr_reader :server
                # port attempted
                attr_reader :port
                # reason for failure
                attr_reader :reason
                # server:: server attempted to connect
                # port:: port attempted to connect on
                # reason: reason for failed connection
                # Failed connection to the server
                def initialize(server, port, reason=nil)
                    @server = server
                    @port = port
                    @reason = reason
                end
            end
        end
    end
end