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

            def self.val(sym)
                s = self.filter(:name => sym.to_s).first
                return s ? s.value : nil
            end

            def self.set(sym, value)
                s = self.find_or_create(:name => sym.to_s)
                s.value = value
                s.save
            end
        end
    end
end