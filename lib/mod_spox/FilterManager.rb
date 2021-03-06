require 'mod_spox/Filter'

module ModSpox
    class FilterManager
        
        def initialize
            @filters = {}
        end
        
        # filter:: ModSpox::Filter object
        # type:: type of message to filter
        def add(filter, type)
            type = Helpers.find_const(type)
            @filters[type] ||= []
            @filters[type] << filter
        end
        
        # filter:: ModSpox::Filter object
        # type:: type of message filter is associated to
        # Remove a filter. If a type is defined, the filter
        # will only be removed from that type. If no type is
        # defined, the filter will be removed completely
        def remove(filter, type=nil)
            if(type.nil?)
                @filters.each do |ar|
                    ar.delete_if do |key, value|
                        value == filter
                    end
                end
            else
                type = Helpers.find_const(type)
                if(@filters[type])
                    key = @filters[type].index(filter)
                    @filters[type].delete(key) if key
                end
            end
        end
        
        # type:: type of message
        # Return array of filters. Will only return
        def filters(type=nil)
            if(type.nil?)
                return @filters.dup
            else
                type = Helpers.find_const(type)
                return @filters[type] ? @filters[type].dup : nil
            end
        end

        # m:: message from pipeline
        # Applies filters to messages from pipeline
        def apply_filters(m)
            @filters.keys.each do |type|
                if(Helpers.type_of?(m, type))
                    @filters[type].each do |f|
                        begin
                            m = f.filter(m)
                            break if m.nil?
                        rescue Object => boom
                            Logger.warn("Failed to apply filter: #{boom}")
                        end
                    end
                    break if m.nil?
                end
            end
            return m
        end
        
        # Remove all filters
        def clear
            @filters = {}
        end
    end
end