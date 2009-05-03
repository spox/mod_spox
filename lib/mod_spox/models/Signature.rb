require 'mod_spox/models/Group'

module ModSpox
    module Models
        # Attributes provided by model:
        # signature:: regex signature
        # params:: Array of parameters to match in signature
        # method:: method to call when matched
        # plugin:: plugin to call when matched
        # description:: description of trigger
        class Signature < Sequel::Model

            many_to_one :group, :class => 'Models::Group'

            def params=(prms)
                raise Exceptions::InvalidType.new('Parameter names must be provided in an array') unless prms.nil? || prms.kind_of?(Array)
                prms = prms.join('|') unless prms.nil?
                super(prms)
            end

            def params
                return values[:params].nil? ? [] : values[:params].split('|')
            end

            def signature=(v)
                v = [Marshal.dump(v)].pack('m')
                super(v)
            end
            
            def signature
                values[:signature] ? Marshal.load(values[:signature].unpack('m')[0]) : nil
            end
            
            def Signature.find_or_create(args)
                t = nil
                if(args.has_key?(:signature) && args.has_key?(:params) && args.has_key?(:method) && args.has_key?(:plugin))
                    args[:params] = [] if args[:params].nil?
                    Signature.filter(:method => args[:method], :plugin => args[:plugin], :params => args[:params].join('|')).each do |s|
                        t = s if s.signature == args[:signature]
                    end
                    args[:params] = nil if args[:params].empty?
                end
                unless(t)
                    t = create(args)
                end
                t.update(:enabled => true)
                return t
            end

        end
    end
end