require 'mod_spox/messages/internal/Response'
module ModSpox
    module Messages
        module Internal
            class NickResponse < Response
                # nick of the bot (model)
                attr_reader :nick
                def initialize(origin, nick)
                    super(origin)
                    @nick = nick
                end
            end
        end
    end
end