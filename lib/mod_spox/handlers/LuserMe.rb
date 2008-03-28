module ModSpox
    module Handlers
        class LuserMe < Handler
            def initialize(handlers)
                handlers[RPL_LUSERME] = self
            end
            def process(string)
                clients = string =~ /(\d+) clients/ ? $1.to_i : 0
                servers = string =~ /(\d+) server/ ? $1.to_i : 0
                return Messages::Incoming::LuserMe.new(string, clients, servers)
            end
        end
    end
end