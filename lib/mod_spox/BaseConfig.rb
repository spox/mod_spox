require 'mod_spox/Exceptions'

module ModSpox

    class BaseConfig
    
        # file_path:: path to configuration file
        # Creates new BaseConfig
        def initialize(file_path)
            @config = Hash.new
            @file_path = file_path
            parse_configuration
        end
        
        # name:: key of config item wanted
        # Provides access to configuration data
        def [](name)
            name = name.to_sym unless name.is_a?(Symbol)
            raise Exceptions::UnknownKey.new("Configuration has no value named: #{name.to_s}") unless @config.has_key?(name)
            return @config[name]
        end
        
        def []=(key, value)
            key = key.to_sym unless key.is_a?(Symbol)
            @config[key] = value
            write_configuration
        end
        
        # Parses the configuration file into a usable Hash
        def parse_configuration
            return unless File.exists?(BotConfig[:userconfigpath])
            IO.readlines(BotConfig[:userconfigpath]).each{|line|
                if(line =~ /^(\S+)\s*=\s*(\S*)\s*$/)
                    @config[$1.to_sym] = $2
                end
            }
        end
        
        # Writes the configuration file out to the provided file_path
        # during initialization
        def write_configuration
            file = File.open(BotConfig[:userconfigpath], 'w')
            @config.each_pair{|k,v|
                file.puts("#{k.to_s}=#{v}")
            }
            file.close
        end
    
    end

end