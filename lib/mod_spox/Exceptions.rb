module ModSpox
    module Exceptions

        class BotException < Exception
        end
        
        class NotImplemented < BotException
        end
    
        class InvalidType < BotException
        end
        
        class InvalidValue < BotException
        end
        
        class AlreadyRunning < BotException
        end
        
        class NotRunning < BotException
        end
        
        class UnknownKey < BotException
        end
        
        class InstallationError < BotException
        end
        
        class LockedObject < BotException
        end
        
        class TimerInUse < BotException
        end
        
        class EmptyQueue < BotException
        end

    end
end