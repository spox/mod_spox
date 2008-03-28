module ModSpox
    module Messages
        module Internal
            class ChangeNick
                # change bot's nick to this nick
                attr_reader :new_nick
                # new_nick: nick to change to
                # Tells the bot it needs to change its nick
                def initialize(new_nick)
                    @new_nick = new_nick
                end
            end
        end
    end
end