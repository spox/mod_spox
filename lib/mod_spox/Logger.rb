require 'logger'
module ModSpox
    class Logger
        class << self
            def logger=(l)
                unless(l.is_a?(::Logger))
                    raise ArgumentError.new('Expecting Logger type')
                end
                @@logger = l
            end
            def method_missing(sym, *args)
                if(class_variable_defined?(:@@logger))
                    if(@@logger.respond_to?(sym))
                        @@logger.send(sym, *args)
                    else
                        raise MethodMissing.new("Failed to find method: #{sym}")
                    end
                end
            end
        end
    end
end
