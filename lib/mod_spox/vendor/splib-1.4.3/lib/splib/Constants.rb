module Splib
    # c:: constant name (String)
    # things:: Array of Object/Module constants to look in
    # Finds a constant if it exists
    # Example:: Foo::Bar 
    # Returns nil if nothing found
    def self.find_const(c, things=[])
        raise ArgumentError.new('Exepcting an array') unless things.is_a?(Array)
        const = nil
        (things + [Object]).each do |base|
            begin
                c.split('::').each do |part|
                    const = const.nil? ? base.const_get(part) : const.const_get(part)
                end
            rescue NameError
                const = nil
            end
            break unless const.nil?
        end
        const
    end

    # a:: an object
    # b:: constant or string
    # Returns true of a is a type of b. b can be given as a String
    # to allow for matching of types contained within a module or
    # for types that may not be loaded
    def self.type_of?(a, b)
        case b
        when String
            if(a.class.to_s.slice(0).chr == '#')
                name = a.class.to_s
                return name.slice(name.index('::')+2, name.length) == b
            else
                const = self.find_const(b)
                return const.nil? ? false : a.is_a?(const)
            end
        when Class
            return a.is_a?(b)
        else
            raise ArgumentError.new('Comparision type must be a string or constant')
        end
    end
end