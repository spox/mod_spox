require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/UserHost'
module ModSpox
    module Handlers
        class YourHost < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_USERHOST][:value]] = self
            end
            #  :not.configured 302 spox :mod_spox=+~mod_spox@some.host
            def process(string)
                begin
                    mod = string.dup
                    mod.slice!(0)
                    server = mod.slice!(0, mod.index(' ')-1)
                    3.times{ mod.slice!(0, mod.index(' ')) }
                    mod.slice!(0)
                    nickname = mod.slice!(0, mod.index('=')-1)
                    mod.slice!(0, 1)
                    username = mod.slice!(0, mod.index('@')-1)
                    mod.slice!(0)
                    host = mod
                    nick = find_model(nickname)
                    nick.username = username
                    nick.host = host
                    return Messages::Incoming::UserHost.new(string, server, nick, username, host)
                rescue Object => boom
                    Logger.error("Failed to process USERHOST message. Reason: #{boom}")
                end
            end
        end
    end
end