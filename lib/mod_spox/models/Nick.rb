require 'socket'
require 'mod_spox/models/Auth'
require 'mod_spox/models/Channel'
require 'mod_spox/models/NickMode'
require 'mod_spox/models/AuthMask'



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

            one_to_many :auths, :one_to_one => true, :class => 'Models::Auth'
            many_to_many :channels, :join_table => :nick_channels, :class => 'Models::Channel'
            one_to_many :modes, :class => 'Models::NickMode'
            many_to_many :auth_masks, :join_table => :auth_masks_nicks, :class => 'Models::AuthMask'

            # nick_name:: nick of user
            # override to downcase nick
            def nick=(nick_name)
                nick_name.downcase!
                super(nick_name)
            end

            def Nick.find_or_create(args)
                args[:nick].downcase! if args[:nick]
                super(args)
            end

            def Nick.filter(args)
                args[:nick].downcase! if args[:nick]
                super(args)
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

            # addr: users address
            # make sure everything is set properly
            # when the address is set
            def address=(addr)
                return if (!values[:address].nil? && !values[:host].nil?) && (values[:address] == addr || values[:host] == addr)
                oldaddress = values[:address]
                begin
                    info =  Object::Socket.getaddrinfo(address, nil)
                    addr = info[0][3]
                    update_values :host => info[0][2]
                    super(addr)
                rescue Object => boom
                    addr = address
                    update_values :host => address
                    super(addr)
                ensure
                    if values[:address] != oldaddress
                        clear_auth 
                    end
                end
            end

            # val:: bool
            # sets if nick is currently visible. if
            # not all relating information is cleared
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
                    remove_all_channels
                end
                super(val)
            end

            def auth
                if(auths.empty?)
                    Auth.find_or_create(:nick_id => pk)
                end
                return auths[0]
            end

            # AuthGroups nick is authed to
            def auth_groups
                g = auths.empty? || auths[0].groups.nil? ? [] : auths[0].groups
                g += auth_masks[0].groups unless auth_masks.empty?
                return g
            end

            # Set nick as member of given group
            def group=(group)
                auth.add_group(group)
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
                auth.authenticated(false)
                NickGroup.filter(:nick_id => pk).destroy
            end

            # Modes associated with this nick
            def nick_modes
                modes
            end

            # Remove all channels
            def clear_channels
                remove_all_channels
                visible = false
            end

            # channel:: Models::Channel
            # Return if nick is operator in given channel
            def is_op?(channel)
                return !modes.filter(:channel => channel).first.mode.index('o').nil?
            end

            # channel:: Models::Channel
            # Return if nick is voiced in given channel
            def is_voice?(channel)
                return !modes.filter(:channel => channel).first.mode.index('v').nil?
            end

            # TODO: rewrite this to work
            def Nick.transfer_groups(old_nick, new_nick)
                NickGroup.filter(:nick_id => old_nick.pk).update(:nick_id => new_nick.pk)
            end

        end
    end
end