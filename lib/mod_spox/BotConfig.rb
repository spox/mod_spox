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
        def self.populate
            gemname, gem = Gem.source_index.find{|name, spec|
                spec.name == 'mod_spox' && spec.version.version = $BOTVERSION
            }
            if(gem)
                p = gem.full_gem_path
                up = $MOD_SPOX_PATH.nil? ? Etc.getpwnam(Etc.getlogin).dir : $MOD_SPOX_PATH
                @@config = {:basepath => p,
                           :libpath => "#{p}/lib/mod_spox",
                           :datapath => "#{p}/data/mod_spox",
                           :pluginpath => "#{p}/data/mod_spox/plugins",
                           :pluginextraspath => "#{p}/data/mod_spox/extras",
                           :userpath => "#{up}/.mod_spox",
                           :userpluginpath => "#{up}/.mod_spox/plugins",
                           :userconfigpath => "#{up}/.mod_spox/config"}
                [@@config[:userpath], @@config[:userpluginpath]].each do |path|
                    Dir.mkdir(path) unless File.exists?(path)
                end
            else
                p gem
                p gemname
                raise Exceptions::InstallationError.new('Failed to find mod_spox gem')
            end
        end
        
        # name:: Name of the path string you would like
        # Provides access to important path values
        def self.[](name)
            BotConfig.populate unless @@config
            name = name.to_sym unless name.is_a?(Symbol)
            raise Exceptions::UnknownKey.new("Failed to find given key: #{name}") unless @@config.has_key?(name)
            return @@config[name]
        end
    
    end

end