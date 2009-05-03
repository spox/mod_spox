module ModSpox
    module Models
        # Attributes provided by model:
        # name:: name of the setting
        # value:: value of the setting
        #
        # This model can be used to store complex objects. These objects are dumped
        # and stored for later retrieval
        # TODO: remove [] from any usage
        class Setting < Sequel::Model

            #serialize(:value, :format => :marshal)

            def name=(setting_name)
                setting_name.downcase!
                super(setting_name)
            end

            def value=(val)
                val = [Marshal.dump(val.dup)].pack('m')
                super(val)
            end

            def value
                return values[:value] ? Marshal.load(values[:value].unpack('m')[0]) : nil
            end

            def self.set(sym, value)
                s = self.find_or_create(:name => sym.to_s)
                s.value = value
                s.save
            end

            def self.val(sym)
                s = self.filter(:name => sym.to_s)
                return s ? nil : s.first.value
            end
        end
    end
end