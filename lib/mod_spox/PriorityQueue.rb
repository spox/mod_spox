module ModSpox
    # This class provides some simple logic for message output. It
    # is basically a priority based queue with some round robin
    # thrown in, just to keep things interesting. This queue provides
    # protection on message output from extreme lag to one target when
    # another target is expecting large quantities out output
    # NOTE: Design help from the great Ryan "pizza_" Flynn
    class PriorityQueue
    
        # Create a priority queue
        def initialize
            @target_queues = {}
            @queues = {:PRIORITY => Array.new, :NEW => Array.new, :NORMAL => Array.new, :WHOCARES => Array.new}
            @lock = Mutex.new
        end
        
        # target:: message target (targets starting with * will be given lowest priority)
        # message:: message to send
        # This prioritizes output to help reduce lag when lots of output
        # is being sent to another target. This will automatically decide
        # how to queue the message based on the target
        def priority_queue(target, message)
            target = target.to_s
            @lock.synchronize do
                target.downcase!
                @target_queues[target] = Queue.new unless @target_queues[target]
                if(target.slice(0,1) == '*')
                    @target_queues[target] << message
                    add_queue(:WHOCARES, @target_queues[target])
                else
                    @target_queues[target] << message
                    if(@target_queues[target].size < 2)
                        add_queue(:NEW, @target_queues[target])
                    else
                        add_queue(:NORMAL, @target_queues[target])
                    end
                end
            end
        end
        
        # message:: message to send
        # This will add messages to the PRIORITY queue which gets
        # sent before all other messages.
        def direct_queue(message)
            @lock.synchronize do
                @target_queues[:general] = Queue.new unless @target_queues[:general]
                @target_queues[:general] << message
                add_queue(:PRIORITY, @target_queues[:general])
            end
        end
        
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
                            m = q.pop
                            add_queue(k, q) unless(q.empty?)
                            break
                        end
                    end
                end
            end
            raise Exceptions::EmptyQueue.new if m.nil?
            return m
        end
        
        private
        
        def add_queue(name, queue)
            unless(@queues[name].include?(queue))
                @queues[name] << queue
            end
        end
    end
end