module ModSpox
    module Handlers
        class MyInfo < Handler
            def initialize(handlers)
                handlers[RPL_MYINFO] = self
            end

            def process(string)
                if(string =~ /^:\S+ \S+ \S+ (\S+) (\S+) (\S+) (\S+)/)
                    servername = $1
                    version = $2
                    usermodes = $3
                    channelmodes = $4
                    return Messages::Incoming::MyInfo.new(string, servername, version, usermodes, channelmodes)
                else
                    Logger.log('Failed to match My Info message')
                    return nil
                end
            end
        end
    end
end