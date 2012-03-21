$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'mod_spox/Logger'

require 'stringio'

class LoggerTest < Test::Unit::TestCase
  def setup
    @io = StringIO.new
    @logger = Logger.new(@io)
    @logger.level = Logger::DEBUG
  end

  def test_debug
    ModSpox::Logger.logger = @logger
    ModSpox::Logger.debug 'fubar'
    @io.rewind
    assert_match(/^D, \[[^\]]+?\]\s+DEBUG -- : fubar\n$/, @io.readline)
  end

  def test_error
    ModSpox::Logger.logger = @logger
    ModSpox::Logger.error 'fubar'
    @io.rewind
    assert_match(/^E, \[[^\]]+?\]\s+ERROR -- : fubar\n$/, @io.readline)
  end

  def test_fatal
    ModSpox::Logger.logger = @logger
    ModSpox::Logger.fatal 'fubar'
    @io.rewind
    assert_match(/^F, \[[^\]]+?\]\s+FATAL -- : fubar\n$/, @io.readline)
  end

  def test_info
    ModSpox::Logger.logger = @logger
    ModSpox::Logger.info 'fubar'
    @io.rewind
    assert_match(/^I, \[[^\]]+?\]\s+INFO -- : fubar\n$/, @io.readline)
  end

  def test_warn
    ModSpox::Logger.logger = @logger
    ModSpox::Logger.warn 'fubar'
    @io.rewind
    assert_match(/^W, \[[^\]]+?\]\s+WARN -- : fubar\n$/, @io.readline)
  end

  def test_unknown
    ModSpox::Logger.logger = @logger
    ModSpox::Logger.unknown 'fubar'
    @io.rewind
    assert_match(/^A, \[[^\]]+?\]\s+ANY -- : fubar\n$/, @io.readline)
  end
end
