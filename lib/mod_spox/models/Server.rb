module ModSpox
    module Models
        # Attributes provided by model:
        # host:: hostname of server
        # port:: port to connect to
        # priority:: priority of this entry (higher number == greater priority)
        # connected:: bot is connected to this server
        class Server < Sequel::Model

            def Server.filter(args={})
                args[:host].downcase! if args.has_key?(:host)
                super(args)
            end
            
            def Server.find_or_create(args={})
                args[:host].downcase! if args.has_key?(:host)
                super(args)
            end

            def host=(host_name)
                host_name.downcase!
                super(host_name)
            end

        end
    end
end