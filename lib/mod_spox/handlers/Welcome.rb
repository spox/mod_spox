require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Welcome < Handler
            def initialize(handlers)
                handlers[RPL_WELCOME] = self
            end
            # >> :holmes.freenode.net 001 spax :Welcome to the freenode IRC Network spax 
            def process(string)
                parse = string.dup
                begin
                    parse.slice!(0)
                    server = parse.slice!(0..parse.index(' ')-1)
                    2.times{parse.slice!(0..parse.index(' '))}
                    nick = parse.slice!(0..parse.index(' ')-1)
                    parse.slice!(0..parse.index(':'))
                    nick = Models::Nick.find_or_create(:nick => nick)
                    nick.botnick = true
                    nick.visible = true
                    nick.save
                    return Messages::Incoming::Welcome.new(string, server, parse, nick, nil, nil)
                rescue Object => boom
                    Logger.warn("Failed to parse welcome message: #{string}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end
        end
    end
end