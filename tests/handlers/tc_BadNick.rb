require 'mod_spox/Logger'
require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/Messages'
require 'test/unit'

class TestBadNickHandler < Test::Unit::TestCase
    def setup
        @handler = ModSpox::Handlers::BadNick.new({})
        @test = {:good => 'fail', :bad => 'fail'}
    end

    def teardown
        #nothing#
    end

    def test_expected
        assert_kind_of(ModSpox::Messages::Incoming::BadNick, @handler.process(@test[:good]))
    end

    def test_unexpected
        assert_nil(@handler.process(@test[:bad]))
    end
end