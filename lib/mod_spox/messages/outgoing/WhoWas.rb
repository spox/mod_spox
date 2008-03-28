module ModSpox
    module Messages
        module Outgoing
            class WhoWas
                # nick to whowas
                attr_reader :nick
                # number of entries to return
                attr_reader :count
                # target server
                attr_reader :target
                # nick:: nick to whowas
                # count:: number of entries to return
                # target:: target server
                # Information about a nick that no longer exists
                def initialize(nick, count='', target='')
                    @nick = nick
                    @count = count
                    @target = target
                end
            end
        end
    end
end