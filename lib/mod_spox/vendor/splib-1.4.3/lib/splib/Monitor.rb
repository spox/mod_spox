require 'thread'

module Splib
    Splib.load :Sleep
    # Basic exception to wakeup a monitor timer
    class Wakeup < Exception
    end
    # Modified Monitor class. Positives included JRuby support, single
    # thread timing
    class Monitor
        # Create a new Monitor
        def initialize
            @threads = []
            @locks = []
            @lock_owner = nil
            @timers = {}
            @timer = start_timer
            @stop = false
            Kernel.at_exit do
                if(@timer)
                    @stop = true
                    @timer.raise Wakeup.new
                end
            end
        end

        # timeout:: Wait for given amount of time
        # Park a thread here
        def wait(timeout=nil)
            raise 'This thread is already a registered sleeper' if @threads.include?(Thread.current)
            Thread.exclusive{ @threads << Thread.current }
            if(timeout)
                timeout = timeout.to_f
                Thread.exclusive{ @timers[Thread.current] = timeout }
                @timer.raise Wakeup.new
            end
            Thread.stop
            Thread.exclusive{ @threads.delete(Thread.current) }
            if(timeout && @timers.has_key?(Thread.current))
                Thread.exclusive{ @timers.delete(Thread.current) }
                @timer.raise Wakeup.new
            end
            true
        end
        # Park thread while block is true
        def wait_while
            while yield
                wait
            end
        end
        # Park thread until block is true
        def wait_until
            until yield
                wait
            end
        end
        # Wake up earliest thread
        def signal
            synchronize do
                while(t = @threads.shift)
                    if(t && t.alive? && t.stop?)
                        t.wakeup
                        break
                    else
                        next
                    end
                end
            end
        end
        # Wake up all threads
        def broadcast
            synchronize do
                @threads.dup.each do |t|
                    t.wakeup if t.alive? && t.stop?
                end
            end
        end
        # Number of threads waiting
        def waiters
            @threads.size
        end
        # Lock the monitor
        def lock
            Thread.exclusive{ do_lock }
            until(owner?(Thread.current)) do
                Thread.stop
            end
        end
        # Unlock the monitor
        def unlock
            do_unlock
        end
        # Attempt to lock. Returns true if lock is aquired and false if not.
        def try_lock
            locked = false
            Thread.exclusive do
                clean
                unless(locked?(false))
                    do_lock
                    locked = true
                else
                    locked = owner?(Thread.current)
                end
            end
            locked
        end
        # cln:: Clean dead threads
        # Is monitor locked
        def locked?(cln=true)
            Thread.exclusive{clean} if cln
            @locks.size > 0 || @lock_owner
        end
        # Lock the monitor, execute block and unlock the monitor
        def synchronize
            result = nil
            lock
            result = yield
            do_unlock
            result
        end

        private


        # This is a simple helper method to help keep threads from ending
        # up stuck waiting for a lock when a thread locks the monitor and
        # then decides to die without unlocking. It is only called when
        # new locks are attempted or a check is made if the monitor is
        # currently locked.
        def clean
            @locks.delete_if{|t|!t.alive?}
            if(@lock_owner && !@lock_owner.alive?)
                @lock_owner = @locks.empty? ? nil : @locks.shift
                @lock_owner.wakeup if @lock_owner && !owner?(Thread.current)
            end
        end

        # Check if the givin thread is the current owner
        def owner?(t)
            @lock_owner == t
        end

        # Aquire monitor lock or be queued for lock
        # NOTE: To make this method more generic and useful, it does
        # not perform a Thread.exclusive, and as such this method should
        # only be called from within a Thread.exclusive{}
        def do_lock
            clean
            if(@lock_owner)
                if(owner?(Thread.current))
                    @locks.unshift(Thread.current)
                else
                    @locks << Thread.current
                end
            else
                @lock_owner = Thread.current
            end
            true
        end

        # Unlock the monitor
        def do_unlock
            unless(owner?(Thread.current))
                raise ThreadError.new("Thread #{Thread.current} is not the current owner: #{@lock_owner}")
            end
            Thread.exclusive do
                @locks.delete_if{|t|!t.alive?}
                unless(@locks.empty?)
                    old_owner = @lock_owner
                    @lock_owner = @locks.shift
                    @lock_owner.wakeup unless old_owner == @lock_owner
                else
                    @lock_owner = nil
                end
            end
        end

        # Starts the timer for waiting threads with a timeout
        def start_timer
            @timer = Thread.new do
                begin
                    until(@stop) do
                        cur = []
                        t = 0
                        Thread.exclusive do
                            t = @timers.values.min
                            cur = @timers.dup
                        end
                        t = 0 if !t.nil? && t < 0
                        a = 0
                        begin
                            a = Splib.sleep(t)
                        rescue Wakeup
                            # do nothing of importance
                        ensure
                            next if t.nil?
                            Thread.exclusive do
                                cur.each_pair do |thread, value|
                                    value -= a
                                    if(value <= 0)
                                        thread.wakeup
                                        @timers.delete(thread)
                                    else
                                        @timers[thread] = value
                                    end
                                end
                            end
                        end
                    end
                rescue
                    retry
                end
            end
        end
    end
end