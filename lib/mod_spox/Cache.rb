module ModSpox
    class Cache
        def initialize(size)
            @size = size
            @cache = Hash.new
            @times = Hash.new
        end
        
        def [](key)
            if(@cache.has_key?(key.to_sym))
                @times[key.to_sym] = Time.now
                return @cache[key.to_sym]
            else
                return nil
            end
        end
        
        def has_key?(key)
            return @cache.has_key?(key.to_sym)
        end
        
        def []=(key, value)
            if(@cache.size > @size)
                key = oldest_key
                unless(key.nil?)
                    @cache.delete(key)
                    @times.delete(key)
                end
            end
            @cache[key.to_sym] = value
            @times[key.to_sym] = Time.now
        end
        
        def delete(key)
            @cache.delete(key.to_sym) if @cache.has_key?(key.to_sym)
            @times.delete(key.to_sym) if @times.has_key?(key.to_sym)
        end
        
        def oldest_key
           return @times.sort{|a,b| a[1] <=> b[1]}[0][0]
        end
    end
end