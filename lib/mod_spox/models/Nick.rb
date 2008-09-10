require 'socket'

module ModSpox
    module Models
        # Attributes provided by model:
        # nick:: nick string
        # username:: username of the user
        # real_name:: real name of the user
        # address:: ip of the user
        # host:: hostname/ip of the user
        # source:: full source string of the user
        # connected_at:: time user connected
        # connected_to:: server user connected to
        # seconds_idle:: seconds user has been idle
        # visible:: can the bot see the user (is in a channel the bot is parked)
        # away:: is nick away
        # botnick:: is the nick of the bot

        class Nick < Sequel::Model

            Nick.after_save :clear_auth

            set_cache Database.cache, :ttl => 3600 unless Database.cache.nil?

            # This method overrides the default filter method
            # on the dataset. This is a pretty ugly hack to
            # get the nick field to be searched properly.
#             def_dataset_method(:filter) do |arg|
#                 return super unless arg.is_a?(Hash)
#                 arg[:nick].downcase! if arg.has_key?(:nick)
#                 Logger.log("ARGS ARE AS FOLLOWS:")
#                 arg.each_pair{|k,v| Logger.log("KEY: #{k} VALUE: #{v}")}
#                 super(arg)
#             end

            def nick=(nick_name)
                values[:nick] = nick_name.downcase
            end

            def Nick.locate(string, create = true)
                nick = nil
                string.downcase!
                nick = Nick.filter(:nick => string).first
                if(!nick && create)
                    nick = Nick.find_or_create(:nick => string)
                end
                return nick
            end

            def address=(address)
                begin
                    info =  Object::Socket.getaddrinfo(address, nil)
                    update_values :address => info[0][3]
                    update_values :host => info[0][2]
                rescue Object => boom
                    update_values :address => address
                    update_values :host => address
                end
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
            end

            # Auth model associated with nick
            def auth
                Auth.find_or_create(:nick_id => pk)
            end

            # AuthGroups nick is authed to
            def auth_groups
                nickgroups = NickGroup.filter(:nick_id => pk)
                if(nickgroups.size < 1)
                    populate_groups
                    nickgroups = NickGroup.filter(:nick_id => pk)
                end
                groups = []
                NickGroup.filter(:nick_id => pk).each do | nickgroup |
                    groups << nickgroup.group
                end
                return groups
            end

            def populate_groups
                auth_ids = []
                group_ids = []
                auth = Auth.filter('nick_id = ?', pk).filter('authed = ?', true).first
                if(auth)
                    auth.groups.each do |group|
                        NickGroup.find_or_create(:nick_id => pk, :group_id => group.pk)
                    end
                end
                Auth.where('mask is not null').each do |a|
                    [source, "#{nick}!#{username}@#{host}", "#{nick}!#{username}@#{address}"].each do |chk_src|
                        Logger.log("Matching AUTH - #{chk_src} against #{a.mask}", 30)
                        if(chk_src =~ /#{a.mask}/)
                            auth_ids << a.pk unless auth_ids.include?(a.pk)
                        end
                    end
                end
                auth_ids.each{|id| AuthGroup.filter(:auth_id => id).each{|ag| group_ids << ag.group_id}}
                group_ids.uniq.each{|id| NickGroup.find_or_create(:nick_id => pk, :group_id => id)}
            end

            # Set nick as member of given group
            def group=(group)
                auth.group = group
            end

            def in_group?(group)
                group = Group.filter(:name => group).first if group.is_a?(String)
                return group.nil? ? false : auth_groups.include?(group)
            end

            # Remove nick from given group
            def remove_group(group)
                auth.remove_group(group)
            end

            # Clear this nick's auth status
            def clear_auth
                auth.authed = false
                NickGroup.filter(:nick_id => pk).destroy
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
                #NickGroup.destroy_all
                Auth.set(:authed => false)
            end

        end
    end
end