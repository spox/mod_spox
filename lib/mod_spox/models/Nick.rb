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

            one_to_many :auths, :one_to_one => true, :class => 'ModSpox::Models::Auth'
            many_to_many :channels, :join_table => :nick_channels, :class => 'ModSpox::Models::Channel'
            one_to_many :modes, :class => 'ModSpox::Models::NickMode'
            many_to_many :auth_masks, :join_table => :auth_masks_nicks, :class => 'ModSpox::Models::AuthMask'

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
                    update :host => info[0][2]
                    super(addr)
                rescue Object => boom
                    super(addr)
                    update :host => address
                ensure
                    if values[:address] != oldaddress
                        auth.update(:authed => false)
                    end
                end
            end

            # val:: bool
            # sets if nick is currently visible. if
            # not all relating information is cleared
            def visible=(val)
                unless(val)
                    update :username => nil
                    update :real_name => nil
                    update :address => nil
                    update :source => nil
                    update :connected_at => nil
                    update :connected_to => nil
                    update :seconds_idle => nil
                    update :away => false
                    remove_all_channels
                    auth.update(:authed => false)
                end
                super(val)
            end

            # Auth model associated with nick
            def auth
                if(auths.empty?)
                    a = Auth.find_or_create(:nick_id => pk)
                    add_auth(a)
                end
                return auths[0]
            end

            # AuthGroups nick is authed to
            def auth_groups
                g = (auth.groups.empty? || !auth.authed) ? [] : auth.groups
                unless(auth_masks.empty?)
                    auth_masks.each{|am| g += am.groups}
                end
                return g
            end

            # Checks nick's source against available
            # authentication masks
            def check_masks
                AuthMask.all.each do |am|
                    add_auth_mask(am) if source =~ /#{am.mask}/ && !auth_masks.include?(am)
                end
            end

            # group:: Models::Group
            # Return if nick is member of given group
            def in_group?(group)
                group = Group.filter(:name => group).first if group.is_a?(String)
                return group.nil? ? false : auth_groups.include?(group)
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
                raise Exceptions::NotInChannel.new(channel) unless channels.include?(channel)
                m = NickMode.filter(:nick_id => pk, :channel_id => channel.pk).first
                return m ? m.set?('o') : false
            end

            # channel:: Models::Channel
            # Return if nick is voiced in given channel
            def is_voice?(channel)
                raise Exceptions::NotInChannel.new(channel) unless channels.include?(channel)
                m = NickMode.filter(:nick_id => pk, :channel_id => channel.pk).first
                return m ? m.set?('v') : false
            end
            
            def set_mode(m)
                m.each_char do |c|
                    update(:mode => "#{mode}#{c}") if mode.index(c).nil?
                end
            end
            
            def unset_mode(m)
                m.each_char do |c|
                    update(:mode => mode.gsub(c,'')) unless mode.index(c).nil?
                end
            end
            
            def mode_set?(m)
                return !mode.index(m).nil?
            end

            def add_channel(c)
                unless(channels.map{|channel| channel.name.downcase}.include?(c.name.downcase))
                    super(c)
                end
            end

            def remove_channel(c)
                unless(channels.map{|channel| channel.name.downcase}.include?(c.name.downcase))
                    super(c)
                end
            end

            # TODO: rewrite this to work
            def Nick.transfer_groups(old_nick, new_nick)
                raise Exceptions::NotImplemented.new
            end

        end
    end
end