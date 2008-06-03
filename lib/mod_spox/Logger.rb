require 'mod_spox/Pool'

module ModSpox

    class Logger
    
        def self.do_initialization
            Logger.fd(nil) unless Logger.class_variable_defined?(:@@fd)
            Logger.severity unless Logger.class_variable_defined?(:@@severity)
            @@lock = Mutex.new unless Logger.class_variable_defined?(:@@lock)
            @@lock.synchronize do
                @@writer = LogWriter.new(@@fd) unless Logger.class_variable_defined?(:@@writer)
                @@initialized = true
            end
        end
        
        # severity:: minimum severity for visible logging
        # Sets the maximum level of visible logs
        def self.severity(severity=1)
            @@severity = severity
        end
        
        # filedes:: file descriptor to log to
        # Sets the file descriptor for logging. By default
        # logs will be sent to STDOUT
        def self.fd(filedes=nil)
            @@fd = filedes.nil? ? $stdout : filedes
        end
        
        # message:: message to log
        # severity:: severity level (lower is more severe)
        # Log a message. It is important to note that the lower the
        # severity level of a message, the better chance it has of
        # being outputted
        def self.log(message, severity=1)
            do_initialization unless Logger.class_variable_defined?(:@@initialized)
            @@writer.log(message) unless @@severity < severity
        end
        
        def self.kill
            @@writer.kill
        end
        
    end
    
    class LogWriter
    
        attr_reader :fd
        
        def initialize(fd)
            @fd = fd
            @kill = false
            @queue = Queue.new
            @thread = Thread.new do
                until(@kill)
                    processor
                end
            end
        end
        
        def kill
            @kill = true
            @queue << "Logger has been told to shut down"
        end
        
        def log(message)
            @queue << message
        end
        
        def processor
            message = @queue.pop
            @fd.puts("LOGGER [#{Time.now}]: #{message}")
        end
        
    end
    
end