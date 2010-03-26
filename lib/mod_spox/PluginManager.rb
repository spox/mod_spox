require 'mod_spox/Plugin'

require 'splib'
Splib.load :CodeReloader, :Constants

require 'mod_spox/Bot'

module ModSpox
    # Manages plugins for mod_spox
    class PluginManager

        # Hash of plugin instances and modules
        attr_reader :plugins

        # args:: Argument hash.
        # :pipeline:: Pipeliner::Pipeline
        # :irc:: BaseIRC::IRC
        # :timer:: ActionTimer::Timer
        # :pool:: ActionPool::Pool
        # Create a new plugin manager
        # :nodoc:
        # {:PluginName => {:module => Module(containing constants), :plugin => Plugin instance}}
        def initialize(args={})
            [:pipeline, :irc, :timer, :pool].each do |x|
                unless(args.has_key?(x))
                    raise ArgumentEror.new "Expecting #{x}"
                end
            end
            @args = args
            @args[:pm] = self
            @plugins = {}
        end

        # args:: Arguments for loading ({:gem => gem_name} or {:file => path})
        # Loads the plugin with the given name
        def load_plugin(args = {})
            plugs = []
            if(args[:gem])
                require args[:gem]
                plugs = create_gem_plugins
            elsif(args[:file])
                plugs = load_plugins_in(args[:file])
            else
                raise ArgumentError.new 'Only :file or :gem types allowed'
            end
            plugs
        end

        # name:: Name of plugin
        # Unloads the plugin with the given name
        def unload_plugin(name)
        end

        # name:: Name of plugin (or :all to reload all plugins)
        # Reloads single or all plugins
        def reload_plugin(name = :all)
        end

        def find_plugins
            {:files => find_local_plugins,
                :gems => find_gem_plugins}
        end

        private

        # Instantiates any plugins found in the ModSpox::Plugins namespace
        # that do not already exist. Returns array of plugin constants
        # created.
        def create_gem_plugins
            plugs = ModSpox::Plugins.constants.map{|x|
                ModSpox::Plugins.const_get(x)}.find_all{|x|
                    x < ModSpox::Plugin && !@plugins.has_key(x)}
            plugs.each do |pl|
                @plugins[pl.to_sym] = {:module => nil, :plugin => pl.new(@args)}
            end
            plugs
        end

        # file:: Path to file
        # Load all plugins within given file
        def load_plugins_in(file)
            plugs = []
            if(File.exists?(file))
                mod = Splib.load_code(file)
                plugs = mod.constants.map{|x|mod.const_get(x)}.find_all{|x|x < ModSpox::Plugin}
                plugs.each do |pl|
                    @plugins[pl.to_s.split('::').last.to_sym] = {:module => mod, :plugin => pl.new(@args)}
                end
            else
                raise ArgumentError.new 'File does not exist'
            end
            plugs
        end

        # Returns a list of all plugins found in local gem list
        def find_gem_plugins
            gems = []
            begin
                require 'rubygems'
                dep = Gem::Dependency.new /^mod_spox_plugin/, nil
                gems = Gem.source_index.search(dep)
            rescue LoadError
                # ignore
            end
            gems
        end

        # Find all local plugins in config directory
        def find_local_plugins
            files = []
            if(File.exists?("#{ModSpox.config_dir}/plugins") && File.directory?("#{ModSpox.config_dir}/plugins"))
                Dir.glob("#{ModSpox.config_dir}/plugins/*.rb"){|x| files << x}
            end
            files
        end
    end
end
