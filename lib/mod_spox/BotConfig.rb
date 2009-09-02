require 'etc'
require 'mod_spox/Exceptions'

module ModSpox

    class BotConfig
    
        @@config = nil
    
        # Populates all important paths. This does not need to
        # be explicitly called though nothing bad will happen if
        # it is. Keys available are:
        # :basepath => path to gem directory
        # :libpath => path to lib directory
        # :datapath => path to data directory
        # :pluginpath => path to plugin directory
        # :pluginextraspath => path to extra functionality plugins
        # :userpath => path to mod_spox directory in user's home directory
        # :userpluginpath => path to user's plugin directory
        # :userconfigpath => path to the user configuration file        
        def BotConfig.populate(createdir=true)
            path = __FILE__.split(File::Separator)
            3.times{ path.pop }
            path = path.join(File::Separator)
            upath = ModSpox.mod_spox_path.nil? ? Etc.getpwnam(Etc.getlogin).dir : ModSpox.mod_spox_path
            @@config = {:basepath => path,
                        :libpath => "#{path}/lib/mod_spox",
                        :datapath => "#{path}/data/mod_spox",
                        :pluginpath => "#{path}/data/mod_spox/plugins",
                        :pluginextraspath => "#{path}/data/mod_spox/extras",
                        :userpath => "#{upath}/.mod_spox",
                        :userpluginpath => "#{upath}/.mod_spox/plugins",
                        :userconfigpath => "#{upath}/.mod_spox/config"}
            if(createdir)
                [@@config[:userpath], @@config[:userpluginpath]].each do |mpath|
                    Dir.mkdir(mpath) unless File.exists?(mpath)
                end
            end
        end
        
        # name:: Name of the path string you would like
        # Provides access to important path values
        def BotConfig.[](name)
            BotConfig.populate unless @@config
            raise ArgumentError.new('Parameter must have a to_s method') unless name.respond_to?(:to_s)
            name = name.to_s.to_sym unless name.is_a?(Symbol)
            raise Exceptions::UnknownKey.new("Failed to find given key: #{name}") unless @@config.has_key?(name)
            return @@config[name]
        end
        
        # Returns if the bot has been configured
        def BotConfig.configured?
            BotConfig.populate(false)
            path = BotConfig[:userpath]
            @@config = nil
            return File.exists?(path)
        end
    
    end

end