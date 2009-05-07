require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Names < Handler
            def initialize(handlers)
                handlers[RPL_NAMREPLY] = self
                handlers[RPL_ENDOFNAMES] = self
                @names = Hash.new
                @raw = Hash.new
            end
     
            def process(string)
                orig = string.dup
                string.slice!(0..string.index(' '))
                type = string.slice!(0..string.index(' ')-1)
                if(type == RPL_NAMREPLY)
                    3.times{ string.slice!(0..string.index(' ')) }
                    chan = string.slice!(0..string.index(' ')-1)
                    string.slice!(0..string.index(':'))
                    @names[chan] = Array.new unless @names[chan]
                    @raw[chan] = Array.new unless @raw[chan]
                    @raw[chan] << orig
                    @names[chan] += string.split
                    return nil
                else
                    2.times{ string.slice!(0..string.index(' ')) }
                    chan = string.slice!(0..string.index(' ')-1)
                    channel = find_model(chan)
                    @raw[chan] << orig if @raw[chan]
                    nicks = Array.new
                    ops = Array.new
                    voice = Array.new
                    raw = @raw[chan].dup if @raw[chan]
                    @names[chan] = [] unless @names[chan].is_a?(Array)
                    @names[chan].each do |n|
                        nick = Models::Nick.find_or_create(:nick => n.gsub(/^[@+]/, ''))
                        nick.visible = true
                        nicks << nick
                        if(n[0] == '@')
                            ops << nick
                            m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                            m.set_mode('o')
                        elsif(n[0] == '+')
                            voice << nick
                            m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                            m.set_mode('v')
                        else
                            m = Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk)
                            m.clear_modes
                        end
                        channel.add_nick(nick)
                    end
                    check_visibility(nicks, channel)
                    @names.delete(chan)
                    @raw.delete(chan)
                    return Messages::Incoming::Names.new(raw, channel, nicks, ops, voice)
                end
            end

            # nicks:: list of nicks in channel
            # channel:: channel nicks are in
            # Remove visibility from any nicks that aren't really
            # in the channel
            def check_visibility(nicks, channel)
                channel.nicks.each do |nick|
                    unless(nicks.include?(nick))
                        channel.remove_nick(nick)
                        unless(nick.botnick)
                            nick.update(:visible => false) if (Models::Nick.filter(:botnick => true).first.channels & nick.channels).empty?
                        end
                    end
                end
            end
        end
    end
end