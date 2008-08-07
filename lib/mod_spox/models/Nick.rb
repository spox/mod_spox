module ModSpox
    module Models
        # Attributes provided by model:
        # nick:: nick string
        # username:: username of the user
        # real_name:: real name of the user
        # address:: hostname/ip of the user
        # source:: full source string of the user
        # connected_at:: time user connected
        # connected_to:: server user connected to
        # seconds_idle:: seconds user has been idle
        # visible:: can the bot see the user (is in a channel the bot is parked)
        # away:: is nick away
        # botnick:: is the nick of the bot
         
        # TODO: for nick field -> "tack a COLLATE NOCASE onto the columns"
        class Nick < Sequel::Model(:nicks)
            
            Nick.after_save :clear_auth
            
            set_cache Database.cache, :ttl => 3600 unless Database.cache.nil?
            
            def Nick.locate(string, create = true)
                nick = nil
                if(Database.type == :pgsql)
                    nick = Nick.filter('nick = lower(?)', string).first
                end
                nick = Nick.find_or_create(:nick => string) if !nick && create
                return nick
            end
            
            def visible=(val)
                unless(val)
                    update_with_params :username => nil
                    update_with_params :real_name => nil
                    update_with_params :address => nil
                    update_with_params :source => nil
                    update_with_params :connected_at => nil
                    update_with_params :connected_to => nil
                    update_with_params :seconds_idle => nil
                    update_with_params :away => false
                end
                update_values :visible => val
            end
                    
            def source=(mask)
                update_values :source => mask
                auth.check_mask(mask)
            end
            
            # Auth model associated with nick
            def auth
                Auth.find_or_create(:nick_id => pk)
            end
            
            # AuthGroups nick is authed to
            def auth_groups
                groups = []
                auth_ids = []
                group_ids = []
                auth = Auth.filter('nick_id = ?', pk).filter('authed = ?', true).first
                if(auth)
                    groups = auth.groups
                end
                Auth.where('mask is not null').each do |a|
                    Logger.log("Matching AUTH against #{a.mask}", 30)
                    if(source =~ /#{a.mask}/)
                        auth_ids << a.pk
                    end
                end
                auth_ids.each{|id| AuthGroup.filter(:auth_id => id).each{|ag| group_ids << ag.group_id}}
                group_ids.each{|id| groups << Group[id]}
                groups.uniq!
                return groups
            end
            
            # Set nick as member of given group
            def group=(group)
                auth.group = group
            end
            
            # Remove nick from given group
            def remove_group(group)
                auth.remove_group(group)
            end
            
            # Clear this nick's auth status
            def clear_auth
                auth.authed = false
            end
            
            # Modes associated with this nick
            def nick_modes
                NickMode.filter(:nick_id => pk)
            end
            
            # Add channel nick is found in
            def channel_add(channel)
                NickChannel.find_or_create(:nick_id => pk, :channel_id => channel.pk)
            end
            
            # Remove channel nick is no longer found in
            def channel_remove(channel)
                NickChannel.filter(:nick_id => pk, :channel_id => channel.pk).first.destroy
            end
            
            # Remove all channels
            def clear_channels
                NickChannel.filter(:nick_id => pk).each{|o|o.destroy}
            end
            
            # Channels nick is currently in
            def channels
                chans = []
                NickChannel.filter(:nick_id => pk).each do |nc|
                    chans << nc.channel
                end
                return chans
            end
            
            # channel:: Models::Channel
            # Return if nick is operator in given channel
            def is_op?(channel)
                NickMode.filter(:channel_id => channel.pk, :nick_id => pk).each do |mode|
                    return true if mode.mode == 'o'
                end
                return false
            end
            
            # channel:: Models::Channel
            # Return if nick is voiced in given channel
            def is_voice?(channel)
                NickMode.filter(:channel_id => channel.pk, :nick_id => pk).each do |mode|
                    return true if mode.mode == 'v'
                end
                return false
            end
            
            # Purge all nick information
            def self.clean
                Nick.set(:username => nil, :real_name => nil, :address => nil,
                                   :source => nil, :connected_at => nil, :connected_to => nil,
                                   :seconds_idle => nil, :away => false, :visible => false, :botnick => false)
                NickMode.destroy_all
                Auth.set(:authed => false)
            end
        
        end
    end
end