module ModSpox
    module Models
        # Attributes provided by model:
        # name:: name of the config item
        # value:: value of the config item
        #
        # It is important to note this model is for storing configuration
        # values only. It will only store strings, not complex objects. If
        # you need to store an object, use the Setting model.
        # TODO: find and remove any [] usage
        class Config < Sequel::Model

            def name=(config_name)
                config_name.downcase!
                super(config_name)
            end

            def Config.val(sym)
                s = Config.filter(:name => "#{sym}").first
                return s ? s.value : nil
            end

            def Config.set(sym, value)
                s = Config.find_or_create(:name => "#{sym}")
                s.value = value
                s.save
            end
        end
    end
end