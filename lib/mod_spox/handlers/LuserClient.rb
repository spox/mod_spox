require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class LuserClient < Handler
            def initialize(handlers)
                handlers[RPL_LUSERCLIENT] = self
            end
            def process(string)
                users = string =~ /(\d+) users/ ? $1 : 0
                invis = string =~ /(\d+) invisible/ ? $1 : 0
                servs = string =~ /(\d+) servers/ ? $1 : 0
                services = string =~ /(\d+) services/ ? $1 : 0
                return Messages::Incoming::LuserClient.new(string, users, invis, servs, services)
            end
        end
    end
end