require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Motd < Handler
            def initialize(handlers)
                handlers[RPL_MOTDSTART] = self
                handlers[RPL_MOTD] = self
                handlers[RPL_ENDOFMOTD] = self
                @motds = Hash.new
                @raw = Hash.new
                @counter = 0
                @waiter = nil
                @lock = Mutex.new
            end
            def process(string)
                if(string =~ /^:(\S+) #{RPL_MOTDSTART.to_s}.*?:-\s?(\S+)/)
                    @motds[$1] = Array.new
                    @raw[$1] = [string]
                    decrement
                    return nil
                elsif(string =~ /^:(\S+) #{RPL_MOTD.to_s}.*?:-\s?(.+)$/)
                    @motds[$1] << $2
                    @raw[$1] << string
                    decrement
                    return nil
                elsif(string =~ /^:(\S+) #{RPL_ENDOFMOTD.to_s}/)
                    check
                    @raw[$1] << string
                    message = Messages::Incoming::Motd.new(@raw[$1].join("\n"), @motds[$1].join("\n"), $1)
                    @motds.delete($1)
                    @raw.delete($1)
                    return message
                else
                    return nil
                end
            end
            
            def preprocess(string)
                return if string =~ /#{RPL_ENDOFMOTD}/
                @lock.synchronize do
                    @waiter = Monitors::Boolean.new if @waiter.nil?
                    @counter += 1
                end
            end
            
            def check(key)
                if(@counter > 0)
                    @waiter.wait
                end
                @counter = 0
                @waiter = nil
            end
            
            def decrement(key)
                @lock.synchronize do
                    @counter -= 1
                    if(@counter < 1)
                        @waiter.wakeup
                    end
                end
            end
            
        end
    end
end