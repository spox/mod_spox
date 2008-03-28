module ModSpox
    module Messages
        module Outgoing
            class Connect
                # server to connect to
                attr_reader :target_server
                # port to connec to
                attr_reader :port
                # remote server to connect to target
                attr_reader :remote_server
                # target_server:: server to connect to
                # port:: target server port
                # remote_server:: remote server to connect to target
                # Request a server to try to establish a connection to
                # another server. This is generally an oper command.
                def initialize(target_server, port, remote_server='')
                    @target_server = target_server
                    @port = port
                    @remote_server = remote_server
                end
            end
        end
    end
end