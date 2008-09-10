module ModSpox
    module Models
        # Attributes provided by model:
        # mode:: Mode that is set
        class NickMode < Sequel::Model

            # Nick mode is associated with
            def nick
                return Nick[nick_id]
            end

            # Channel mode is associated with
            def channel
                return Channel[channel_id]
            end
        end
    end
end