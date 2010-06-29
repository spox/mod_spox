module Splib
    # path:: path to file
    # Read contents of file
    def self.read_file(path)
        file = File.open(path, 'rb')
        cont = file.read
        file.close
        cont
    end
    # path:: path to ruby file
    # type:: return constants only of given type
    # Find all constants in a given ruby file. Array of 
    # symbols is returned
    def self.discover_constants(path, type=nil)
        raise ArgumentError.new('Failed to locate plugin file') unless File.exists?(path)
        consts = []
        sandbox = Module.new
        sandbox.module_eval(self.read_file(path))
        sandbox.constants.each do |const|
            klass = sandbox.const_get(const)
            if(type.nil? || (type && klass < type))
                sklass = klass.to_s.slice(klass.to_s.rindex(':')+1, klass.to_s.length)
                consts << sklass.to_sym
            end
        end
        return consts
    end

    # path:: path to ruby file
    # holder:: module holding loaded ruby code
    # Load code from a ruby file into a module
    def self.load_code(path, holder=nil)
        if(holder)
            raise ArgumentError.new('Expecting a module containing loaded code') unless holder.respond_to?(:path)
        else
            holder = self.create_holder(path)
        end
        holder.module_eval(self.read_file(path))
        holder
    end

    # holder:: module holding loaded ruby code
    # Reload the code within the module
    def self.reload_code(holder)
        raise ArgumentError.new('Expecting a module containing loaded code') unless holder.respond_to?(:path)
        self.load_code(holder.path)
    end

    # path:: path to ruby code
    # Creates a module to hold loaded code
    def self.create_holder(path)
        return Module.new do
            @path = path
            def self.path
                @path
            end
        end
    end
end