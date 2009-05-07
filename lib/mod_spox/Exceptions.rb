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

        class Disconnected < BotException
        end

        class NotInChannel < BotException
            attr_reader :channel
            def initialize(channel)
                @channel = channel
            end
            def to_s
                "Bot is not currently in channel: #{@channel}"
            end
        end

        class QuietChannel < BotException
            attr_reader :channel
            def initialize(channel)
                @channel = channel
            end
            def to_s
                "Bot is not allowed to speak in channel: #{@channel}"
            end
        end

    end
end