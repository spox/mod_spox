$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'mod_spox/PluginManager'

require 'ostruct'


class Bot < OpenStruct
end

class PluginManagerTest < Test::Unit::TestCase
    def setup
        bot = ModSpox::Bot.new
        @pm = ModSpox::PluginManager.new(bot)
        @dummy = File.dirname(__FILE__) + '/plugins/DummyPlugin.rb'
    end

    def test_file_load
        size = @pm.plugins.size
        assert_kind_of(Class, @pm.load_plugin(:file => @dummy).first)
        assert_equal(size + 1, @pm.plugins.size)
        assert(@pm.plugins[:Plug])
        assert_kind_of(ModSpox::Plugin, @pm.plugins[:Plug][:plugin])
        assert_kind_of(Module, @pm.plugins[:Plug][:module])
    end

    def test_unload
        size = @pm.plugins.size
        @pm.load_plugin(:file => @dummy)
        assert(@pm.plugins[:Plug])
        @pm.unload_plugin(:Plug)
        assert_equal(size, @pm.plugins.size)
    end

    def test_file_reload
        @pm.load_plugin(:file => @dummy)
        assert(@pm.plugins[:Plug])
        @pm.plugins[:Plug][:plugin].var = :foo
        assert_equal(:foo, @pm.plugins[:Plug][:plugin].var)
        @pm.reload_plugin(:Plug)
        assert_not_equal(:foo, @pm.plugins[:Plug][:plugin].var)
        assert_nil(@pm.plugins[:Plug][:plugin].var)
    end

    def test_find_files
        ModSpox.config_dir = File.dirname(__FILE__)
        plugs = @pm.find_plugins
        assert_equal("#{File.dirname(__FILE__)}/plugins/DummyPlugin.rb", plugs[:files].first)
    end

    def test_gem_load
        flunk 'Write this test'
    end
end
