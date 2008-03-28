module ModSpox
    module Handlers
        class Mode < Handler
            def initialize(handlers)
                handlers[:MODE] = self
            end
            
            def process(string)
                if(string =~ /^:([^!]+)!.+?MODE\s(\S+)\s(\S+)$/) # this is for modes applied to the channel
                    source = find_model($1)
                    channel = find_model($2)
                    full_mode = $3
                    action = full_mode[0].chr
                    full_mode.slice(0).each_char{|c|
                        Models::ChannelMode.find_or_create(:channel_id => channel.pk, :mode => c) if action == '+'
                        if(action == '-' && model = Models::ChannelMode.filter(:channel_id => channel.pk, :mode => c).first)
                            model.destroy!
                        end
                    }
                    return Messages::Incoming::Mode.new(string, full_mode, source, nil, channel)
                elsif(string =~ /^:([^!]+)!.+MODE\s(\S+)\s(.+)$/) # this is for modes applied to nick
                    # implement later #
                elsif(string =~ /^:([^!]+)!.+MODE\s(\S+)\s(\S+)\s(.+)$/)
                    source = find_model($1)
                    channel = find_model($2)
                    full_modes = $3
                    targets = $4
                    action = full_mode[0].chr
                    nicks = Array.new
                    full_mode.slice(0).length.times{|i|
                        nick = find_model(targets.scan(/\S+/)[i])
                        nicks << nick
                        mode = full_mode[i + 1].chr
                        Models::NickMode.find_or_create(:channel_id => channel.pk, :nick_id => nick.pk, :mode => mode) if action == '+'
                        if(action == '-' && model = Models::NickMode.filter(:channel_id => channel.pk, :nick_id => nick.pk, :mode => mode).first)
                            model.destroy!
                        end
                    }
                    nicks = nicks[0] if nicks.size == 1
                    return Messages::Incoming::Mode.new(string, full_mode, source, nicks, channel)
                else
                    Logger.log('Failed to parse MODE message')
                end
            end
        end
    end
end