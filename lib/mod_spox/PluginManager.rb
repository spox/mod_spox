require 'mod_spox/Plugin'

require 'splib'
Splib.load :CodeReloader, :Constants

require 'mod_spox/Bot'
# TODO: We need to have the plugin manager keep track of what is to be
# => loaded on startup. Thus, we need to add a pstore file in the config directory
# => to keep track of what plugins we need to attempt to load on startup.
# => There is also the fact that we need to provide builtin plugins for basic
# => functionality. These include the old userinfo, ponger, and related plugins. Should
# => probably be thrown into a plugins subdirectory here since they will be considered
# => integrated parts of the bot and any extra plugins will be lone files or gems
module ModSpox
    # Manages plugins for mod_spox
    class PluginManager

        # Hash of plugin instances and modules
        attr_reader :plugins

        # bot:: Bot instance
        # Create a new plugin manager
        # :nodoc:
        # {:PluginName => {:module => Module(containing constants), :plugin => Plugin instance}}
        def initialize(bot)
            unless(bot.is_a?(Bot))
                raise ArgumentError.new("Expecting type Bot. Received type #{bot.class}")
            end
            @bot = bot
            @plugins = {}
            load_builtins
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
            name = name.to_sym
            if(@plugins[name])
                @plugins[name][:plugin].destroy
                @plugins.delete(name)
            else
                raise NameError.new "No plugin found with name: #{name}"
            end
            true
        end

        # name:: Name of plugin (or :all to reload all plugins)
        # Reloads single or all plugins
        def reload_plugin(name = :all)
            name = name.to_sym
            plugs = []
            if(name == :all)
                pls = []
                @plugins.values.each do |x|
                    pls.push(x[:module].path) if x[:module]
                    x[:plugin].destroy
                end
                @plugins.clear
                pls.each{|x| plugs += load_plugin(:file => x)}
                plugs += create_gem_plugins
            else
                raise NameError.new "No plugin found with name: #{name}" unless @plugins[name]
                path = @plugins[name][:module] ? @plugins[name][:module].path : nil
                unload_plugin(name)
                plugs = path ? load_plugin(:file => path) : load_plugin(:gem => name)
            end
            plugs
        end

        # Returns listing of all available plugins
        def find_plugins
            {:files => find_local_plugins,
                :gems => find_gem_plugins}
        end

        private

        # Loads all builtin plugins
        def load_builtins
            Dir.glob(File.dirname(__FILE__)+'/plugins/*.rb').each do |file|
                require file
            end
            create_non_module_plugins
        end

        # Instantiates any plugins found in the ModSpox::Plugins namespace
        # that do not already exist. Returns array of plugin constants
        # created.
        def create_non_module_plugins
            plugs = ModSpox::Plugins.constants.map{|x|
                ModSpox::Plugins.const_get(x)}.find_all{|x|
                    x < ModSpox::Plugin && !@plugins.has_key?(x)}
            plugs.each do |pl|
                @plugins[pl.to_s.split('::').last.to_sym] = {:module => nil, :plugin => pl.new(@bot)}
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
                    @plugins[pl.to_s.split('::').last.to_sym] = {:module => mod, :plugin => pl.new(@bot)}
                    Logger.info "New plugin loaded: #{pl}"
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
