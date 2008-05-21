module ModSpox
    module Handlers
        class Who < Handler
            def initialize(handlers)
                handlers[RPL_WHOREPLY] = self
                handlers[RPL_ENDOFWHO] = self
                @cache = Hash.new
                @raw_cache = Hash.new
            end
            def process(string)
                if(string =~ /#{RPL_WHOREPLY}\s\S+\s(\S+|\*|\*\s\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s:(\d)\s(.+)$/)
                    # Items matched are as follows:
                    # 1: location
                    # 2: username
                    # 3: host
                    # 4: server
                    # 5: nick
                    # 6: info
                    # 7: hops
                    # 8: realname
                    location = $1 unless $1.include?('*')
                    location = $5 if $5 == '*'
                    location = $1.gsub(/\*\s/, '') if location.include?('* ')
                    info = $6
                    nick = find_model($5)
                    nick.username = $2
                    nick.address = $3
                    nick.real_name = $8
                    nick.connected_to = $4
                    nick.away = info =~ /G/ ? true : false
                    nick.save
                    @cache[location] = Array.new unless @cache[location]
                    @cache[location] << nick
                    @raw_cache[location] = Array.new unless @raw_cache[location]
                    @raw_cache[location] << string
                    if(location[0].chr !~ /[A-Za-z]/)
                        channel = find_model(location)
                        Models::NickChannel.find_or_create(:channel_id => channel.pk, :nick_id => nick.pk)
                        if(info.include?('+'))
                            Models::NickMode.find_or_create(:channel_id => channel.pk, :nick_id => nick.pk, :mode => 'v')
                        elsif(info.include?('@'))
                            Models::NickMode.find_or_create(:channel_id => channel.pk, :nick_id => nick.pk, :mode => 'o')
                        else
                            Models::NickMode.filter(:channel_id => channel.pk, :nick_id => nick.pk).each{|m| m.destroy}
                        end
                    end
                    return nil
                elsif(string =~ /#{RPL_ENDOFWHO}\s\S+\s(\S+)\s/)
                    location = $1
                    loc = find_model(location)
                    @raw_cache[location] << string
                    message = Messages::Incoming::Who.new(@raw_cache[location].join("\n"), loc, @cache[location])
                    @raw_cache.delete(location)
                    @cache.delete(location)
                    return message
                else
                    Logger.log('Failed to match RPL_WHO type message')
                    return nil
                end
            end
        end
    end
end