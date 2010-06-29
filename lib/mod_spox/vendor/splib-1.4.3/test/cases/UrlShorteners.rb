require 'splib'
require 'test/unit'

class UrlShortenersTest < Test::Unit::TestCase
    def setup
        Splib.load :UrlShorteners
    end

    def test_tiny_url
        assert_match(/^http:\/\/[\w|\.|\/]+$/, Splib.tiny_url('www.google.com'))
    end

    def test_trim_url
        assert_match(/^http:\/\/[\w|\.|\/]+$/, Splib.trim_url('www.google.com'))
    end

    def test_isgd_url
        assert_match(/^http:\/\/[\w|\.|\/]+$/, Splib.isgd_url('www.google.com'))
    end

    def test_shortest_url
        assert_match(/^http:\/\/[\w|\.|\/]+$/, Splib.shortest_url('www.google.com'))
    end
end