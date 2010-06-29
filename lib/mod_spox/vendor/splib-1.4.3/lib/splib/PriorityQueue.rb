Splib.load :Monitor

module Splib
    # Exception raised when queue is empty
    class EmptyQueue < RuntimeError
    end
    # This class provides some simple logic for item output. It is
    # basically a priority based queue with some round robin thrown
    # in to keep things interesting. This queue provides an easy way
    # for many threads to populate it without drowning out each other.
    # NOTE: Design help from the great Ryan "pizza_" Flynn
    class PriorityQueue

        # args:: config arguments
        #   :raise_on_empty
        # whocares:: lambda{|target| true||false}
        # Create a priority queue
        def initialize(*args, &whocares)
            @raise = args.include?(:raise_on_empty)
            @whocares = whocares
            @target_queues = {}
            @queues = {:PRIORITY => [], :NEW => [], :NORMAL => [], :WHOCARES => []}
            @lock = Splib::Monitor.new
        end
        
        # target:: target queue
        # item:: item to queue
        # This prioritizes output to help reduce lag when lots of output
        # is being sent to another target. This will automatically decide
        # how to queue the item based on the target
        def prioritized_queue(target, item)
            raise NameError.new('The target :internal_prio is a restricted target') if target == :internal_prio
            @lock.synchronize do
                @target_queues[target] = [] unless @target_queues[target]
                if(@whocares && @whocares.call(target))
                    @target_queues[target] << item
                    add_queue(:WHOCARES, @target_queues[target])
                else
                    @target_queues[target] << item
                    if(@target_queues[target].size < 2)
                        add_queue(:NEW, @target_queues[target])
                    else
                        add_queue(:NORMAL, @target_queues[target])
                    end
                end
                @lock.signal
            end
            item
        end
        
        # item:: item to queue
        # This will add item to the PRIORITY queue which gets
        # sent before all other items.
        def direct_queue(message)
            @lock.synchronize do
                @target_queues[:internal_prio] = [] unless @target_queues[:internal_prio]
                @target_queues[:internal_prio] << message
                add_queue(:PRIORITY, @target_queues[:internal_prio])
                @lock.signal
            end
            message
        end

        # raise_e:: raise an exception on empty
        # Returns the next message to send. This method decides what
        # message to send based on the priority of the message. It
        # will throw an Exceptions::EmptyQueue when there are no messages
        # left.
        def pop
            m = nil
            @lock.synchronize do
                [:PRIORITY, :NEW, :NORMAL, :WHOCARES].each do |k|
                    unless(@queues[k].empty?)
                        q = @queues[k].shift
                        unless(q.empty?)
                            m = q.shift
                            add_queue(k, q) unless(q.empty?)
                            break
                        end
                    end
                end
            end
            unless(m)
                if(@raise)
                    raise EmptyQueue.new('Queue is currently empty')
                else
                    @lock.wait_while{ empty? }
                    m = pop
                end
            end
            m
        end

        # Returns true if queue is empty
        def empty?
            @lock.synchronize{@target_queues.values.find{|n|!n.empty?}.nil?}
        end

        alias :push :prioritized_queue
        alias :<< :direct_queue

        private
        
        def add_queue(name, queue)
            unless(@queues[name].include?(queue))
                @queues[name] << queue
            end
        end
    end
end