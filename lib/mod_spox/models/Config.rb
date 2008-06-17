module ModSpox
    module Models
        # Attributes provided by model:
        # name:: name of the config item
        # value:: value of the config item
        # 
        # It is important to note this model is for storing configuration
        # values only. It will only store strings, not complex objects. If
        # you need to store an object, use the Setting model.
        class Config < Sequel::Model(:configs)

            # key:: name of the config item
            # Returns the value of config item named the given key
            def self.[](key)
                key = key.to_s if key.is_a?(Symbol)
                match = Config.filter(:name => key).first
                return match ? match.value : nil
            end
            
            # key:: name of the config item
            # val:: value of the config item
            # Modifies or creates config item and stores the value
            def self.[]=(key, val)
                key = key.to_s if key.is_a?(Symbol)
                model = Config.find_or_create(:name => key)
                model.update_with_params(:value => val)
                model.save
            end
        end
    end
end