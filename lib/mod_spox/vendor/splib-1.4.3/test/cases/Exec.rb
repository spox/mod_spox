require 'splib'
require 'test/unit'

class ExecTest < Test::Unit::TestCase
    def setup
        Splib.load :Exec
        Splib.load :Sleep
    end

    def test_exec
        assert_raise(IOError) do
            Splib.exec('/bin/sh -c "echo test"', 10, 1)
        end
        assert_raise(Timeout::Error) do
            Splib.exec('/bin/sh -c "while [ true ]; do true; done;"', 1)
        end
        assert_equal("test\n", Splib.exec('/bin/sh -c "echo test"'))
    end

    def test_running
        output = nil
        Thread.new do
            output = Splib.exec('/bin/sh -c "sleep 0.4; echo done"')
        end
        Kernel.sleep(0.1)
        assert_equal(1, Splib.running_procs.size)
        Kernel.sleep(0.5)
        assert_equal("done\n", output)
        assert_equal(0, Splib.running_procs.size)
    end
end