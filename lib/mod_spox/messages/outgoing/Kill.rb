module ModSpox
    module Messages
        module Outgoing
            class Kill
                # nick to kill
                attr_reader :nick
                # reason for kill
                attr_reader :comment
                # nick:: nick to kill
                # comment:: comment about kill
                # Kill connection between given nick and server
                def initialize(nick, comment)
                    @nick = nick
                    @comment = comment
                end
            end
        end
    end
end