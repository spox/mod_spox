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
                    nick = find_model($1)
                    nick.username = $2
                    nick.address = $3
                    nick.real_name = $4
                    @cache[$1] = Messages::Incoming::Whois.new(nick)
                    @cache[$1].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISCHANNELS}\s\S+\s(\S+)\s:(.+)$/)
                    nick = $1
                    $2.split(/\s/).each{|chan|
                        channel = find_model(chan.gsub(/^[@\+]/, ''))
                        @cache[nick].channels_push(channel)
                        if(chan[0].chr == '@')
                            Models::NickMode.find_or_create(:nick_id => @cache[nick].pk, :mode => 'o', :channel_id => channel.pk)
                        elsif(chan[0].chr == '+')
                            Models::NickMode.find_or_create(:nick_id => @cache[nick].pk, :mode => 'v', :channel_id => channel.pk)
                        else
                            Models::NickMode.filter(:nick_id => @cache[nick].nick.pk, :channel_id => channel.pk).each{|m| m.destroy}
                        end
                    }
                    @cache[$1].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISSERVER}\s\S+\s(\S+)\s(\S+)\s:(.+)$/)
                    @cache[$1].nick.connected_to = $2
                    @cache[$1].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISIDENTIFIED}\s\S+\s(\S+)\s/)
                    @cache[$1].nick.auth.services_identified = true
                    @cache[$1].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISIDLE}\s\S+\s(\S+)\s(\d+)\s(\d+)\s:(.+?),(.+?)/)
                    @cache[$1].nick.seconds_idle = $2.to_i
                    @cache[$1].nick.connected_at = Time.at($3.to_i)
                    @cache[$1].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_WHOISOPERATOR}\s\S+\s(\S+)/)
                    @cache[$1].raw_push(string)
                    return nil
                elsif(string =~ /#{RPL_ENDOFWHOIS}\s\S+\s(\S+)\s:/)
                    @cache[$1].raw_push(string)
                    message = @cache[$1]
                    message.lock
                    @cache[$1].nick.save
                    @cache.delete($1)
                    return message
                else
                    Logger.log('Failed to parse WHOIS type reply')
                    return nil
                end
            end
        end
    end
end