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

            def find_or_create(args)
                args[:name].downcase! if args[:name]
                super(args)
            end

            def filter(args)
                args[:name].downcase! if args[:name]
                super(args)
            end

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

            def Setting.set(sym, value)
                sym = sym.to_s.downcase
                s = Setting.find_or_create(:name => "#{sym}")
                s.value = value
                s.save
            end

            def Setting.val(sym)
                sym = sym.to_s.downcase
                s = Setting.filter(:name => "#{sym}").first
                return s ? s.value : nil
            end
        end
    end
end