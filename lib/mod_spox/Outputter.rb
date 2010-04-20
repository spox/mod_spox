require 'thread'
require 'splib'
Splib.load :PriorityQueue, :Monitor

module ModSpox
    # The Outputter object is used to properly queue messages
    # into the given socket. It works as an intermediary between
    # the program and the output socket to ensure we get proper
    # queueing.
    class Outputter
        # Used for queueing output
        attr_reader :queue
        # q:: Splib::PriorityQueue
        # Create a new Outputter
        def initialize(q = nil)
            @queue = Queue.new
            @sockq = q
            @thread = nil
            @stop = false
            @lock = Splib::Monitor.new
        end

        # q:: Splib::PriorityQueue
        # Set the queue to use
        def queue=(q)
            @lock.synchronize{ @sockq = q }
        end

        # Start the outputter
        def start
            raise 'Already running' if @thread && @thread.alive?
            @thread = Thread.new do
                Logger.debug 'Output thread is now running'
                until(@stop) do
                    m = @queue.pop
                    next unless m
                    if(@sockq.nil?)
                        Logger.debug 'No output queue defined. Message dropped.'
                        next
                    end
                    parts = m.split
                    if(parts.last[0,1] == ':')
                        @lock.synchronize do
                            @sockq.push(parts[parts.size - 2].to_sym, m)
                        end
                    else
                        @lock.synchronize{ @sockq.push(:default, m) }
                    end
                    Logger.debug "Outgoing message queued: #{m}"
                end
                Logger.debug 'Output thread has completed and is now stopped'
            end
            true
        end

        # Stop the outputter
        def stop
            @stop = true
            @queue << nil
            @thread.join
            @queue.clear
            @thread = nil
            true
        end
    end
end
