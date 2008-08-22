module ModSpox
    module Models
        # Attributes provided by model:
        # trigger:: trigger to match
        # active:: trigger is active
        class Trigger < Sequel::Model(:triggers)
            set_schema do
                primary_key :id, :null => false
                varchar :trigger, :unique => true, :null => false
                boolean :active, :null => false, :default => false
            end
        end
    end
end