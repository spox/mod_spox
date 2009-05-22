require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Nick < Handler
            def initialize(handlers)
                handlers[:NICK] = self
            end
            # :spox!~spox@some.random.host NICK :flock_of_deer
            def process(string)
                orig = string.dup
                string = string.dup
                begin
                    string.slice!(0)
                    old_nick = find_model(string.slice!(0..string.index('!')-1))
                    string.slice!(0..string.index(':'))
                    new_nick = find_model(string)
                    old_nick.channels.each do |channel|
                        channel.remove_nick(old_nick)
                        channel.add_nick(new_nick)
                        m = Models::NickMode.filter(:nick_id => old_nick.pk, :channel_id => channel.pk).first
                        if(m)
                            m.nick_id = new_nick.pk
                            m.save
                        end
                    end
                    new_nick.username = old_nick.username
                    new_nick.address = old_nick.address
                    new_nick.real_name = old_nick.real_name
                    new_nick.connected_to = old_nick.connected_to
                    new_nick.away = old_nick.away
                    new_nick.visible = true
                    new_nick.save_changes
                    old_nick.visible = false
                    old_nick.remove_all_channels
                    if(old_nick.botnick == true)
                        old_nick.botnick = false
                        new_nick.botnick = true
                    end
                    new_nick.save
                    old_nick.save
                    return Messages::Incoming::Nick.new(orig, old_nick, new_nick)
                rescue Object => boom
                    Logger.error("Failed to parse NICK message: #{orig}")
                    return nil
                end
            end
        end
    end
end