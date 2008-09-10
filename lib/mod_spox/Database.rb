module ModSpox

    class Database

        def Database.db=(database)
            @@db = nil
            @@db = database
        end

        def Database.type=(type)
            @@type = nil
            @@type = type
        end

        def Database.cache=(cache)
            @@cache = nil
            @@cache = cache
        end

        def Database.cache
            return Database.class_variable_defined?(:@@cache) ? @@cache : nil
        end

        def Database.type
            return Database.class_variable_defined?(:@@type) ? @@type : nil
        end

        def Database.db
            return Database.class_variable_defined?(:@@db) ? @@db : nil
        end

        def Database.reconnect
            begin
                @@db.test_connection
                Logger.log('Database connection appears to be active. Closing.')
                @@db.disconnect
            rescue Object => boom
                Logger.log('Database connection does not appear to be active.')
            ensure
                Logger.log('Reconnecting to database.')
                ModSpox.setup_adapter
            end
        end

    end

end