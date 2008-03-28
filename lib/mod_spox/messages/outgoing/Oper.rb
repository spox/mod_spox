module ModSpox
    module Messages
        module Outgoing
            class Oper
                # login name
                attr_reader :name
                # user's password
                attr_reader :password
                # name:: login name
                # password:: user's password
                # Create new Oper message
                def initialize(name, password)
                    @name = name
                    @password = password
                end
            end
        end
    end
end