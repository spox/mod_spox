module ModSpox

    class Database
    
        def self.db=(database)
            @@db = nil
            @@db = database
        end
        
        def self.type=(type)
            @@type = nil
            @@type = type
        end
        
        def self.type
            return Database.class_variable_defined?(:@@type) ? @@type : nil
        end
        
        def self.db
            return Database.class_variable_defined?(:@@db) ? @@db : nil
        end
    
    end

end