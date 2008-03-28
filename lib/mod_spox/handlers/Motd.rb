module ModSpox
    module Handlers
        class Motd < Handler
            def initialize(handlers)
                handlers[RPL_MOTDSTART] = self
                handlers[RPL_MOTD] = self
                handlers[RPL_ENDOFMOTD] = self
                @motds = Hash.new
                @raw = Hash.new
            end
            def process(string)
                if(string =~ /^:(\S+) #{RPL_MOTDSTART.to_s}.*?:-\s?(\S+)/)
                    @motds[$1] = Array.new
                    @raw[$1] = [string]
                    return
                elsif(string =~ /^:(\S+) #{RPL_MOTD.to_s}.*?:-\s?(.+)$/)
                    @motds[$1] << $2
                    @raw[$1] << string
                    return
                elsif(string =~ /^:(\S+) #{RPL_ENDOFMOTD.to_s}/)
                    @raw[$1] << string
                    message = Messages::Incoming::Motd.new(@raw[$1].join("\n"), @motds[$1].join("\n"), $1)
                    @motds.delete($1)
                    @raw.delete($1)
                    return message
                end
            end
        end
    end
end