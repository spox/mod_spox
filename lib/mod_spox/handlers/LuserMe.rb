require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/LuserMe'
module ModSpox
    module Handlers
        class LuserMe < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_LUSERME][:value]] = self
            end
            def process(string)
                clients = string =~ /(\d+) clients/ ? $1.to_i : 0
                servers = string =~ /(\d+) server/ ? $1.to_i : 0
                return Messages::Incoming::LuserMe.new(string, clients, servers)
            end
        end
    end
end