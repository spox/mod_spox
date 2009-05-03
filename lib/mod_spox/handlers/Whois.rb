require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Whois < Handler
            def initialize(handlers)
                handlers[RPL_WHOISUSER] = self
                handlers[RPL_WHOISSERVER] = self
                handlers[RPL_WHOISOPERATOR] = self
                handlers[RPL_WHOISIDLE] = self
                handlers[RPL_WHOISCHANNELS] = self
                handlers[RPL_WHOISIDENTIFIED] = self
                handlers[RPL_ENDOFWHOIS] = self
                @cache = Hash.new
                @raw = Hash.new
            end
            
            def process(string)
                if(string =~ /#{RPL_WHOISUSER}\s\S+\s(\S+)\s(\S+)\s(\S+)\s\*\s:(.+)$/)
                    key = $1
                    nick = find_model($1)
                    nick.username = $2
                    nick.address = $3
                    nick.real_name = $4
                    nick.save_changes
                    @cache[$1] = Messages::Incoming::Whois.new(nick)
                    @cache[$1].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISCHANNELS}\s\S+\s(\S+)\s:(.+)$/)
                    nick = $1
                    @cache[nick] = Messages::Incoming::Whois.new(find_model(nick)) unless @cache[nick]
                    @cache[$1].raw_push(string)
                    $2.split(/\s/).each{|chan|
                        channel = find_model(chan.gsub(/^[@\+]/, ''))
                        channel.add_nick(nick)
                        @cache[nick].channels_push(channel)
                        if(chan[0].chr == '@')
                            Models::NickMode.find_or_create(:nick_id => @cache[nick].nick.pk, :mode => 'o', :channel_id => channel.pk)
                        elsif(chan[0].chr == '+')
                            Models::NickMode.find_or_create(:nick_id => @cache[nick].nick.pk, :mode => 'v', :channel_id => channel.pk)
                        else
                            Models::NickMode.filter(:nick_id => @cache[nick].nick.pk, :channel_id => channel.pk).destroy
                        end
                    }
                    return nil
                elsif(string =~ /#{RPL_WHOISSERVER}\s\S+\s(\S+)\s(\S+)\s:(.+)$/)
                    nick = $1
                    @cache[nick] = Messages::Incoming::Whois.new(find_model(nick)) unless @cache[nick]
                    @cache[nick].nick.connected_to = $2
                    @cache[nick].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISIDENTIFIED}\s\S+\s(\S+)\s/)
                    nick = $1
                    @cache[nick] = Messages::Incoming::Whois.new(find_model(nick)) unless @cache[nick]
                    @cache[nick].nick.auth.services_identified = true
                    @cache[nick].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISIDLE}\s\S+\s(\S+)\s(\d+)\s(\d+)\s:(.+?),(.+?)/)
                    nick = $1
                    @cache[nick] = Messages::Incoming::Whois.new(find_model(nick)) unless @cache[nick]
                    @cache[nick].nick.seconds_idle = $2.to_i
                    @cache[nick].nick.connected_at = Time.at($3.to_i)
                    @cache[nick].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISOPERATOR}\s\S+\s(\S+)/)
                    nick = $1
                    @cache[nick] = Messages::Incoming::Whois.new(find_model(nick)) unless @cache[nick]
                    @cache[nick].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_ENDOFWHOIS}\s\S+\s(\S+)\s:/)
                    nick = $1
                    @cache[nick] = Messages::Incoming::Whois.new(find_model(nick)) unless @cache[nick]
                    @cache[nick].raw_push(string)
                    message = @cache[nick]
                    message.lock
                    @cache[nick].nick.save
                    @cache.delete(nick)
                    return message
                else
                    Logger.warn('Failed to parse WHOIS type reply')
                    return nil
                end
            end
        end
    end
end