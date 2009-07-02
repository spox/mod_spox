require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Motd'
module ModSpox
    module Handlers
        class Motd < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_MOTDSTART][:value]] = self
                handlers[RFC[:RPL_MOTD][:value]] = self
                handlers[RFC[:RPL_ENDOFMOTD][:value]] = self
                @motds = Hash.new
                @raw = Hash.new
            end
            def process(string)
                if(string =~ /^:(\S+) #{RFC[:RPL_MOTDSTART][:value]}.*?:-\s?(\S+)/)
                    @motds[$1] = Array.new
                    @raw[$1] = [string]
                    return nil
                elsif(string =~ /^:(\S+) #{RFC[:RPL_MOTD][:value]}.*?:-\s?(.+)$/)
                    @motds[$1] ||= []
                    @raw[$1] ||= []
                    @motds[$1] << $2
                    @raw[$1] << string
                    return nil
                elsif(string =~ /^:(\S+) #{RFC[:RPL_ENDOFMOTD][:value]}/)
                    @raw[$1] ||= []
                    @motds[$1] ||= []
                    @raw[$1] << string
                    message = Messages::Incoming::Motd.new(@raw[$1].join("\n"), @motds[$1].join("\n"), $1)
                    @motds.delete($1)
                    @raw.delete($1)
                    return message
                else
                    return nil
                end
            end
        end
    end
end