# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'mod_spox/PluginManager'

class PluginManagerTest < Test::Unit::TestCase
    def setup
        @pm = ModSpox::PluginManager.new(:irc => nil, :pool => nil, :timer => nil, :pipeline => nil)
        @dummy = File.dirname(__FILE__) + '/DummyPlugin.rb'
    end

    def test_file_load
        assert_kind_of(Class, @pm.load_plugin(:file => @dummy).first)
        assert_equal(1, @pm.plugins.size)
        assert(@pm.plugins[:Plug])
        assert_kind_of(ModSpox::Plugin, @pm.plugins[:Plug][:plugin])
        assert_kind_of(Module, @pm.plugins[:Plug][:module])
    end

    def test_file_unload
        @pm.load_plugin(:file => @dummy)
        assert(@pm.plugins[:Plug])
        @pm.unload_plugin(:Plug)
        assert(@pm.plugins.empty?)
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
end
