require 'logger'
module ModSpox

    class Logger
        
        def Logger.initialize(logger, level)
            l = {:info => ::Logger::INFO, :error => ::Logger::ERROR, :warn => ::Logger::WARN, :fatal => ::Logger::FATAL}
            @@log = logger.is_a?(::Logger) ? logger : nil
            @@log.level = l[level]
        end
        
        def Logger.warn(s)
            @@log.warn(s) if Logger.log?
        end
        
        def Logger.info(s)
            @@log.info(s) if Logger.log?
        end
        
        def Logger.fatal(s)
            @@log.fatal(s) if Logger.log?
        end
        
        def Logger.error(s)
            @@log.error(s) if Logger.log?
        end
        
        def Logger.log?
            Logger.class_variable_defined?(:@@log)
        end

        def Logger.raw
            Logger.log? ? @@log : nil
        end
        
    end
end