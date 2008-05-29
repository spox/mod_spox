require 'mod_spox/messages/incoming/Message'
module ModSpox
    module Messages
        module Incoming
            class Whois < Message
                # Nick of user
                attr_reader :nick
                # Channels user is found in
                attr_accessor :channels
                # Raw whois string
                attr_accessor :raw
                
                def initialize(nick)
                    @nick = nick
                    @channels = Array.new
                    @raw = Array.new
                    @locked = false
                end
                
                # channel:: Channel
                # Adds channel to list
                def channels_push(channel)
                    restricted if @locked
                    @channels << channel
                end
                
                # string:: string
                # Adds string to raw whois info
                def raw_push(string)
                    restricted if @locked
                    @raw << string
                end
                
                # Locks the object's custom methods
                def lock
                    @locked = true
                    @raw_content = @raw.join("\n")
                end
                
                private
                
                def restricted
                    raise Exceptions::LockedObject.new('Whois message can no longer be modified')
                end
            end
        end
    end
end