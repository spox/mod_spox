module ModSpox

    class Logger
        
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
            Logger.fd(nil) unless Logger.class_variable_defined?(:@@fd)
            Logger.severity unless Logger.class_variable_defined?(:@@severity)
            @@fd.puts("LOGGER [#{Time.now}]: #{message}") unless @@severity < severity
        end
        
    end
    
end