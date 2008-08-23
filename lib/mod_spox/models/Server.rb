module ModSpox
    module Models
        # Attributes provided by model:
        # host:: hostname of server
        # port:: port to connect to
        # priority:: priority of this entry (higher number == greater priority)
        # connected:: bot is connected to this server
        class Server < Sequel::Model(:servers)
            set_schema do
                primary_key :id, :null => false
                varchar :host, :null => false
                integer :port, :null => false, :default => 6667
                integer :priority, :null => false, :default => 0
                boolean :connected, :null => false, :default => false
                index [:host, :port], :unique => true
            end
            
            def host=(host_name)
                update_values :host => host_name.downcase
            end
            
        end
    end
end