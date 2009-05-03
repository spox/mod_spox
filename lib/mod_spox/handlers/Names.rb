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
                if(string =~ /#{RPL_NAMREPLY}.*?(\S+) :(.+)$/)
                    chan = $1
                    nicks = $2
                    @names[chan] = Array.new unless @names[chan]
                    @raw[chan] = Array.new unless @raw[chan]
                    if(@raw[chan])
                        @raw[chan] << string
                    else
                        @raw[chan] = [string]
                    end
                    @names[chan] += nicks.split(' ')
                    return nil
                elsif(string =~ /#{RPL_ENDOFNAMES}.*?(\S+) :/)
                    chan = $1
                    @raw[chan] << string if @raw.has_key?(chan)
                    channel = find_model(chan)
                    nicks = Array.new
                    ops = Array.new
                    voice = Array.new
                    raw = @raw[chan]
                    @names[chan].each do |n|
                        nick = Models::Nick.find_or_create(n.gsub(/^[@+]/, '').downcase)
                        nick.visible = true
                        nicks << nick
                        if(n[0].chr == '@')
                            ops << nick
                            Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk, :mode => 'o')
                        elsif(n[0].chr == '+')
                            voice << nick
                            Models::NickMode.find_or_create(:nick_id => nick.pk, :channel_id => channel.pk, :mode => 'v')
                        else
                            nick.remove_all_modes
                        end
                        channel.add_nick(nick)
                    end
                    check_visibility(nicks, channel)
                    @names.delete(chan)
                    @raw.delete(chan)
                    return Messages::Incoming::Names.new(raw, channel, nicks, ops, voice)
                else
                    return nil
                end
            end

            # nicks:: list of nicks in channel
            # channel:: channel nicks are in
            # Remove visibility from any nicks that aren't really
            # in the channel
            def check_visibility(nicks, channel)
                Models::Nick.filter(:channel => channel, :visible => true).each do |n|
                    n.visible = false unless nicks.include?(n)
                end
            end
        end
    end
end