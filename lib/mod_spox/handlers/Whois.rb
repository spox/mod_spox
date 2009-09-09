require 'mod_spox/handlers/Handler'
require 'mod_spox/messages/incoming/Whois'
module ModSpox
    module Handlers
        class Whois < Handler
            def initialize(handlers)
                handlers[RFC[:RPL_WHOISUSER][:value]] = self
                handlers[RFC[:RPL_WHOISSERVER][:value]] = self
                handlers[RFC[:RPL_WHOISOPERATOR][:value]] = self
                handlers[RFC[:RPL_WHOISIDLE][:value]] = self
                handlers[RFC[:RPL_WHOISCHANNELS][:value]] = self
                handlers[RFC[:RPL_WHOISIDENTIFIED][:value]] = self
                handlers[RFC[:RPL_ENDOFWHOIS][:value]] = self
                @cache = Hash.new
                @raw = Hash.new
            end
            
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    until(string.slice(0..string.index(' ')-1) ==RFC[:RPL_WHOISUSER][:value] ||
                            string.slice(0..string.index(' ')-1) ==RFC[:RPL_WHOISSERVER][:value] ||
                            string.slice(0..string.index(' ')-1) ==RFC[:RPL_WHOISOPERATOR][:value] ||
                            string.slice(0..string.index(' ')-1) ==RFC[:RPL_WHOISIDLE][:value] ||
                            string.slice(0..string.index(' ')-1) ==RFC[:RPL_WHOISCHANNELS][:value] ||
                            string.slice(0..string.index(' ')-1) ==RFC[:RPL_WHOISIDENTIFIED][:value] ||
                            string.slice(0..string.index(' ')-1) ==RFC[:RPL_ENDOFWHOIS][:value])
                        string.slice!(0..string.index(' '))
                    end
                    case string.slice!(0..string.index(' ')-1)
                        when RFC[:RPL_WHOISUSER][:value]
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
                        when RFC[:RPL_WHOISCHANNELS][:value]
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            string.slice!(0..string.index(':'))
                            string.split.each do |c|
                                channel = find_model(['@','+'].include?(c.slice(0, 1)) ? c.slice(1..c.size) : c)
                                channel.add_nick(nick)
                                @cache[nick.nick].channels_push(channel)
                                if(c.slice(0, 1) == '@')
                                    m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                                    m.set_mode('o')
                                elsif(c.slice(0, 1) == '+')
                                    m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                                    m.set_mode('v')
                                else
                                    m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                                    m.clear_modes
                                end
                            end
                            @cache[nick.nick].raw_push(orig)
                        when RFC[:RPL_WHOISSERVER][:value]
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            string.slice!(0)
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            nick.connected_to = string.slice!(0..string.index(' ')-1)
                            nick.save_changes
                            @cache[nick.nick].raw_push(orig)
                        when RFC[:RPL_WHOISIDENTIFIED][:value]
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            nick.auth.services_identified = true
                            @cache[nick.nick].raw_push(orig)
                        when RFC[:RPL_WHOISIDLE][:value]
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            string.slice!(0)
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            nick.seconds_idle = string.slice!(0..string.index(' ')-1).to_i
                            string.slice!(0)
                            nick.connected_at = Time.at(string.slice!(0..string.index(' ')-1).to_i)
                            nick.save_changes
                            @cache[nick.nick].raw_push(orig)
                        when RFC[:RPL_WHOISOPERATOR][:value]
                            2.times{string.slice!(0..string.index(' '))}
                            nick = find_model(string.slice!(0..string.index(' ')-1))
                            string.slice!(0)
                            @cache[nick.nick] = Messages::Incoming::Whois.new(nick) unless @cache[nick.nick]
                            @cache[nick.nick].raw_push(orig)
                        when RFC[:RPL_ENDOFWHOIS][:value]
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
                rescue Object => boom
                    Logger.error("Failed to parse WHOIS type reply: #{orig}")
                    raise Exceptions::GeneralException.new(boom)
                end
            end

        end
    end
end