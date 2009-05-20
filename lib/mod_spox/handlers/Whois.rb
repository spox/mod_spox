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
                orig = string.dup
                string = string.dup
                begin
                    until(string.slice(0..string.index(' ')-1) == RPL_WHOISUSER ||
                            string.slice(0..string.index(' ')-1) == RPL_WHOISSERVER ||
                            string.slice(0..string.index(' ')-1) == RPL_WHOISOPERATOR ||
                            string.slice(0..string.index(' ')-1) == RPL_WHOISIDLE ||
                            string.slice(0..string.index(' ')-1) == RPL_WHOISCHANNELS ||
                            string.slice(0..string.index(' ')-1) == RPL_WHOISIDENTIFIED ||
                            string.slice(0..string.index(' ')-1) == RPL_ENDOFWHOIS)
                        string.slice!(0..string.index(' '))
                    end
                    case string.slice!(0..string.index(' ')-1)
                        when RPL_WHOISUSER
                            string.slice!(0)
                            string.slice!(0..string.index(' '))
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            string.slice!(0)
                            nick.username = string.slice!(0..string.index(' ')-1)
                            string.slice!(0)
                            nick.address = string.slice!(0..string.index(' ')-1)
                            string.slice!(0..string.index(':'))
                            nick.real_name = string
                            nick.save_changes
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick)
                            @cache[nick.nick].raw_push(orig)
                        when RPL_WHOISCHANNELS
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            string.slice!(0..string.index(':'))
                            string.split.each do |c|
                                channel = find_model(['@','+'].include?(c.slice(0)) ? c.slice(1..c.size) : c)
                                channel.add_nick(nick)
                                @cache[nick.nick].channels_push(channel)
                                if(c[0].chr == '@')
                                    m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                                    m.set_mode('o')
                                elsif(c[0].chr == '+')
                                    m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                                    m.set_mode('v')
                                else
                                    m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                                    m.clear_modes
                                end
                            end
                            @cache[nick.nick].raw_push(orig)
                        when RPL_WHOISSERVER
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            string.slice!(0)
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            nick.connected_to = string.slice!(0..string.index(' ')-1)
                            nick.save_changes
                            @cache[nick.nick].raw_push(orig)
                        when RPL_WHOISIDENTIFIED
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            nick.auth.services_identified = true
                            @cache[nick.nick].raw_push(orig)
                        when RPL_WHOISIDLE
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            string.slice!(0)
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            nick.seconds_idle = string.slice!(0..string.index(' ')-1).to_i
                            string.slice!(0)
                            nick.connected_at = Time.at(string.slice!(0..string.index(' ')-1).to_i)
                            nick.save_changes
                            @cache[nick.nick].raw_push(orig)
                        when RPL_WHOISOPERATOR
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            string.slice!(0)
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            @cache[nick.nick].raw_push(orig)
                        when RPL_ENDOFWHOIS
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            @cache[nick.nick].raw_push(orig)
                            message = @cache[nick.nick]
                            message.lock
                            @cache.delete(nick.nick)
                            return message
                        else
                            Logger.error("Failed to parse WHOIS type reply. Unknown part found: #{orig}")
                    end
                    return nil
                rescue Object
                    Logger.error("Failed to parse WHOIS type reply: #{orig}")
                    return nil
                end
            end

        end
    end
end