require 'thread'
require 'splib'
Splib.load :PriorityQueue

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
        def initialize(q)
            @queue = Queue.new
            @sockq = q
            @thread = nil
            @stop = false
        end

        # Start the outputter
        def start
            raise 'Already running' if @thread && @thread.alive?
            @thread = Thread.new do
                until(@stop) do
                    m = @queue.pop
                    next unless m
                    parts = m.split
                    if(parts.last[0,1] == ':')
                        @sockq.push(parts[parts.size - 2].to_sym, m)
                    else
                        @sockq.push(:default, m)
                    end
                end
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
