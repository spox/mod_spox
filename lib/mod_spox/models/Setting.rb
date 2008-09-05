module ModSpox
    module Models
        # Attributes provided by model:
        # name:: name of the setting
        # value:: value of the setting
        # 
        # This model can be used to store complex objects. These objects are dumped
        # and stored for later retrieval
        class Setting < Sequel::Model
            
            set_schema do 
                primary_key :id, :null => false
                varchar :name, :null => false, :unique => true
                text :value
            end
            
            def name=(setting_name)
                update_values :name => setting_name.downcase
            end
            
            def value=(val)
                update_values(:value => [Marshal.dump(val.dup)].pack('m'))
            end
            
            def value
                return values[:value] ? Marshal.load(values[:value].unpack('m')[0]) : nil
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
            # Note: Will fail if attempting to save hashes. Must set value explicitly
            def self.[]=(key, val)
                key = key.to_s if key.is_a?(Symbol)
                model = Setting.find_or_create(:name => key)
                model.update_with_params(:value => [Marshal.dump(val.dup)].pack('m'))
            end
        end
    end
end