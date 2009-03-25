module ModSpox
    module Messages
        module Internal
            class EstablishConnection
                # server to connect to
                attr_reader :server
                # port to connect to
                attr_reader :port
                # password for connection to server
                attr_reader :password
                # server:: Server to connect to
                # port:: Port to connect to
                # password:: password to connect
                def initialize(server=nil, port=nil, password=nil)
                    @server = server
                    @port = port
                    @password = password
                end
            end
        end
    end
end