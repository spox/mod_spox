module ModSpox
    module Models
        # Attributes provided by model:
        # host:: hostname of server
        # port:: port to connect to
        # priority:: priority of this entry (higher number == greater priority)
        # connected:: bot is connected to this server
        class Server < Sequel::Model

            def host=(host_name)
                update_values :host => host_name.downcase
            end

        end
    end
end