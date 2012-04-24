$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'mod_spox/socket'

require 'socket'

class SocketTest < Test::Unit::TestCase
  def setup
    @server = TCPServer.new(9090)
    @output = []
    @sock = nil
    @thread = Thread.new do
      loop do
        @sock = @server.accept
        @output << @sock.readline
      end
    end
  end
  def teardown
    @thread.raise 'stop'
    @output.clear
    @server.close
    @server = nil
    @sock = nil
  end

  def test_create
    socket = ModSpox::Socket.new(:server => 'localhost', :port => 9090)
    assert_kind_of(ModSpox::Socket, socket)
    assert_raise(ArgumentError) do
      ModSpox::Socket.new(:port => -1)
    end
  end

  def test_server_set
    socket = ModSpox::Socket.new
    assert_nil(socket.server)
    socket.server = 'localhost'
    assert_equal('localhost', socket.server)
  end

  def test_port_set
    socket = ModSpox::Socket.new
    assert_nil(socket.port)
    socket.port = 9090
    assert_equal(9090, socket.port)
    assert_raise(ArgumentError){ socket.port = -1 }
    assert_equal(9090, socket.port)
    socket.port = '8800'
    assert_equal(8800, socket.port)
  end
  
  def test_connect
    socket = ModSpox::Socket.new(:server => 'localhost', :port => 9090)
    assert(socket.connect)
    sleep(0.05)
    assert_not_nil(@sock)
    socket.write("test")
    sleep(0.01)
    assert_equal("test\n", @output.pop)
  end
end
