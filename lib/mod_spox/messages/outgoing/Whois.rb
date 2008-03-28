module ModSpox
    module Messages
        module Outgoing
            class Whois
                # nick to whois
                attr_reader :nick
                # server to query
                attr_reader :target_server
                # nick:: nick to whois
                # target_server:: server to query
                # Query information about a user
                def initialize(nick, target_server='')
                    @nick = nick
                    @target_server = target_server
                end
            end
        end
    end
end