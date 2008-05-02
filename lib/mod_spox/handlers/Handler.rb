module ModSpox
    module Handlers
    
        class Handler
        
            def process(data)
                raise Exceptions::NotImplemented.new('Method has not been implemented')
            end
            
            protected
            
            def find_model(string)
                @@channel_cache = {} unless Handler.class_variable_defined?(:@@channel_cache)
                @@nick_cache = {} unless Handler.class_variable_defined?(:@@nick_cache)
                if(string =~ /^[A-Za-z\|\\\{\}\[\]\^\`~\_\-]+[A-Za-z0-9\|\\\{\}\[\]\^\`~\_\-]*$/)
                    Logger.log("Model: #{string} -> Nick")
                    if(@@nick_cache.has_key?(string.to_sym))
                        begin
                            nick = Models::Nick[@@nick_cache[string.to_sym]]
                            Logger.log("Handler cache hit for nick: #{string}", 30)
                        rescue Object => boom
                            Logger.log("Failed to grab cached nick: #{boom}")
                        end
                    end
                    unless(nick)
                        nick = Models::Nick.find_or_create(:nick => string)
                        @@nick_cache[string.to_sym] = nick.pk
                        Logger.log("Nick was retrieved from database")
                    end
                    return nick
                elsif(string =~ /^[&#+!]/)
                    Logger.log("Model: #{string} -> Channel")
                    if(@@channel_cache.has_key?(string.to_sym))
                        begin
                            channel = Models::Channel[@@channel_cache[string.to_sym]]
                            Logger.log("Handler cache hit for channel: #{string}", 30)
                        rescue Object => boom
                            Logger.log("Failed to grab cached channel: #{boom}")
                        end
                    end
                    unless(channel)
                        channel = Models::Channel.find_or_create(:name => string)
                        @@channel_cache[string.to_sym] = channel.pk
                        Logger.log("Channel was retrieved from database")
                    end
                    return channel
                elsif(model = Models::Server.filter(:host => string, :connected => true).first)
                    Logger.log("Model: #{string} -> Server")
                    return model
                else
                    Logger.log("FAIL Model: #{string} -> No match")
                    return string
                end
            end
        
        end
        
    end
end