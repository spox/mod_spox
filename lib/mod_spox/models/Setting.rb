require 'base64'

module ModSpox
    module Models
        # Attributes provided by model:
        # name:: name of the setting
        # value:: value of the setting
        # 
        # This model can be used to store complex objects. These objects are dumped
        # and stored for later retrieval
        class Setting < Sequel::Model(:settings)
            
            def value=(val)
                set(:value => Marshal.dump(val))
            end
            
            def value
                return values[:value] ? Marshal.load(values[:value]) : nil
            end
            
            # key:: name of the setting
            # Returns the setting with the given name
            def self.[](key)
                key = key.to_s if key.is_a?(Symbol)
                setting = Setting.filter(:name => key).first
                return setting ? setting.value : nil
            end
            
            # key:: name of the setting
            # val:: value of the setting
            # Stores the val in setting named by the given key            
            def self.[]=(key, val)
                key = key.to_s if key.is_a?(Symbol)
                model = Setting.find_or_create(:name => key)
                model.value = val
                model.save
            end
        end
    end
end