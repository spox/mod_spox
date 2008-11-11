require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Nick < Handler
            def initialize(handlers)
                handlers[:NICK] = self
            end
            def process(string)
                if(string =~ /^:([^!]+)!\S+\sNICK\s:(.+)$/)
                    old_nick = find_model($1)
                    new_nick = find_model($2)
                    new_nick.visible = true
                    old_nick.channels.each do |channel|
                        new_nick.channel_add(channel)
                        Models::NickMode.find_or_create(:nick_id => new_nick.pk, :channel_id => channel.pk, :mode => 'o') if old_nick.is_op?(channel)
                        Models::NickMode.find_or_create(:nick_id => new_nick.pk, :channel_id => channel.pk, :mode => 'v') if old_nick.is_voice?(channel)
                        Models::NickMode.filter(:nick_id => old_nick.pk, :channel_id => channel.pk).destroy
                    end
                    new_nick.username = old_nick.username
                    new_nick.address = old_nick.address
                    new_nick.real_name = old_nick.real_name
                    new_nick.connected_to = old_nick.connected_to
                    new_nick.away = old_nick.away
                    new_nick.visible = true
                    new_nick.save_changes
                    Models::Nick.transfer_groups(old_nick, new_nick)
                    old_nick.visible = false
                    old_nick.clear_channels
                    if(old_nick.botnick == true)
                        old_nick.botnick = false
                        new_nick.botnick = true
                    end
                    new_nick.save
                    old_nick.save
                    return Messages::Incoming::Nick.new(string, old_nick, new_nick)
                else
                    Logger.log('Failed to parse NICK message')
                    return nil
                end
            end
        end
    end
end