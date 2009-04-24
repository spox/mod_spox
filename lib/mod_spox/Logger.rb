require 'logger'
module ModSpox

    class Logger
        
        def Logger.initialize(logger)
            @@log = logger.is_a?(::Logger) ? logger : nil
        end
        
        def Logger.warn(s)
            @@log.warn(s) unless @@log.nil?
        end
        
        def Logger.info(s)
            @@log.info(s) unless @@log.nil?
        end
        
        def Logger.fatal(s)
            @@log.fatal(s) unless @@log.nil?
        end
        
        def Logger.error(s)
            @@log.error(s) unless @@log.nil?
        end
        
    end
end