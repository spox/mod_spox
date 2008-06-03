module ModSpox
    class Cache
        def initialize(size)
            @size = size
            @cache = Hash.new
            @times = Hash.new
            @store_lock = Mutex.new
            @read_lock = Mutex.new
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
            @read_lock.synchronize do
                return @cache.has_key?(key.to_sym)
            end
        end
        
        def []=(key, value)
            @store_lock.synchronize do
                if(@cache.size > @size)
                    del_key = oldest_key
                    unless(key.nil?)
                        @cache.delete(del_key)
                        @times.delete(del_key)
                    end
                end
                @cache[key.to_sym] = value
                @times[key.to_sym] = Time.now
            end
        end
        
        def delete(key)
            @read_lock.synchronize do
                @cache.delete(key.to_sym) if @cache.has_key?(key.to_sym)
                @times.delete(key.to_sym) if @times.has_key?(key.to_sym)
            end
        end
        
        private
        
        def oldest_key
            result = nil
            @read_lock.synchronize do
                result = @times.sort{|a,b| a[1] <=> b[1]}[0][0]
            end
            return result
        end
    end
end