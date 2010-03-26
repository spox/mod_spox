# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'mod_spox/PluginManager'

class PluginManagerTest < Test::Unit::TestCase
    def setup
        @pm = ModSpox::PluginManager.new(:irc => nil, :pool => nil, :timer => nil, :pipeline => nil)
    end

    def test_file_load
        assert_kind_of(Class, @pm.load_plugin(:file => File.dirname(__FILE__) + '/DummyPlugin.rb').first)
        assert_equal(1, @pm.plugins.size)
        assert(@pm.plugins[:Plug])
        assert_kind_of(ModSpox::Plugin, @pm.plugins[:Plug][:plugin])
        assert_kind_of(Module, @pm.plugins[:Plug][:module])
    end
end
