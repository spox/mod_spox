module ModSpox
    module Handlers
        class Mode < Handler
            def initialize(handlers)
                handlers[:MODE] = self
            end
            
            def process(string)
                begin
                    if(string =~ /^:([^!]+)!.+?MODE\s(\S+)\s(\S+)$/) # this is for modes applied to the channel
                        source = find_model($1)
                        channel = find_model($2)
                        full_mode = $3
                        action = full_mode[0].chr
                        full_mode.slice(0).each_char{|c|
                            Models::ChannelMode.find_or_create(:channel_id => channel.pk, :mode => c) if action == '+'
                            if(action == '-' && model = Models::ChannelMode.filter(:channel_id => channel.pk, :mode => c).first)
                                model.destroy
                            end
                        }
                        return Messages::Incoming::Mode.new(string, full_mode, source, nil, channel)
                    #elsif(string =~ /^:([^!]+)!.+MODE\s(\S+)\s(.+)$/) # this is for modes applied to nick
                     #   raise Exceptions::BotException.new("Matched unimplemented mode string")
                    elsif(string =~ /^:([^!]+)!.+MODE\s(\S+)\s(\S+)\s(.+)$/)
                        source = find_model($1)
                        channel = find_model($2)
                        full_modes = $3
                        targets = $4
                        action = full_modes[0].chr
                        nicks = Array.new
                        full_modes.sub(/^./, '').length.times do |i|
                            nick = find_model(targets.scan(/\S+/)[i])
                            nicks << nick
                            if(nick.is_a?(Models::Nick))
                                mode = full_modes[i + 1].chr
                                Models::NickMode.find_or_create(:channel_id => channel.pk, :nick_id => nick.pk, :mode => mode) if action == '+'
                                if(action == '-' && model = Models::NickMode.filter(:channel_id => channel.pk, :nick_id => nick.pk, :mode => mode).first)
                                    model.destroy
                                end
                            end
                        end
                        nicks = nicks[0] if nicks.size == 1
                        return Messages::Incoming::Mode.new(string, full_modes, source, nicks, channel)
                    else
                        Logger.log('Failed to parse MODE message')
                    end
                rescue Object => boom
                    Logger.log("Failed to process MODE message. Reason: #{boom}")
                end
                return nil
            end
        end
    end
end