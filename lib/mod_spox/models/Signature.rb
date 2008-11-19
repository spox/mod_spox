module ModSpox
    module Models
        # Attributes provided by model:
        # signature:: regex signature
        # params:: Array of parameters to match in signature
        # method:: method to call when matched
        # plugin:: plugin to call when matched
        # description:: description of trigger
        class Signature < Sequel::Model

            serialize(:signature, :format => :marshal)

            def params=(prms)
                raise InvalidType.new('Parameter names must be provided in an array') unless prms.kind_of?(Array)
                update_values(:params => prms.join('|'))
            end

            def params
                return values[:params].nil? ? [] : values[:params].split('|')
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