module ModSpox
    module Models
        # Attributes provided by model:
        # signature:: regex signature
        # params:: Array of parameters to match in signature
        # method:: method to call when matched
        # plugin:: plugin to call when matched
        # description:: description of trigger
        class Signature < Sequel::Model
            
            set_schema do
                primary_key :id, :null => false
                varchar :signature, :null => false
                varchar :params
                foreign_key :group_id, :table => :groups, :default => nil
                varchar :method, :null => false
                varchar :plugin, :null => false
                varchar :description
                varchar :requirement, :null => false, :default => 'both'
            end
            
            def params=(prms)
                raise InvalidType.new('Parameter names must be provided in an array') unless prms.kind_of?(Array)
                update_values(:params => prms.join('|'))
            end
        
            def params
                return values[:params].nil? ? [] : values[:params].split('|')
            end
            
            def signature=(sig)
                update_values(:signature => [Marshal.dump(sig)].pack('m'))
            end
            
            def signature
                return values[:signature] ? Marshal.load(values[:signature].unpack('m')[0]) : nil
            end
            
            def group
                Group[group_id]
            end
            
            def group=(group)
                update_values :group_id => group.pk
            end

        end
    end
end