module ModSpox
    module Messages
        module Outgoing
            class User
                # username of user
                attr_reader :username
                # real name of user
                attr_reader :real_name
                # mode of user
                attr_reader :mode
                # username:: username of user
                # real_name:: real name of user
                # mode:: default mode (see RFC 2812 for proper mode values)
                # Create new User message
                def initialize(username, real_name, mode=0)
                    @username = username
                    @real_name = real_name
                    @mode = mode
                end
            end
        end
    end
end