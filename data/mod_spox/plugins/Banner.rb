['mod_spox/messages/outgoing/ChannelMode',
 'mod_spox/messages/outgoing/Kick',
 'mod_spox/messages/internal/TimerAdd',
 'mod_spox/messages/outgoing/Invite'].each{|f| require f}
 
class Banner < ModSpox::Plugin

    include Models
    include Messages::Outgoing

    def initialize(pipeline)
        super
        admin = Group.find_or_create(:name => 'banner')
        add_sig(:sig => 'ban (\S+)', :method => :default_ban, :group => admin, :desc => 'Kickban given nick from current channel', :params => [:nick])
        add_sig(:sig => 'ban (\S+) (\S+)', :method => :channel_ban, :group => admin, :desc => 'Kickban given nick from given channel', :params => [:nick, :channel])
        add_sig(:sig => 'ban (\S+) (\S+) (\d+) ?(.+)?', :method => :full_ban, :group => admin, :desc => 'Kickban given nick from given channel for given number of seconds', :params => [:nick, :channel, :time, :message])
        add_sig(:sig => 'banmask (\S+) (\S+) (\d+) ?(.+)?', :method => :message_mask_ban, :group => admin, :desc => 'Kickban given mask from given channel for given number of seconds providing an optional message', :params => [:mask, :channel, :time, :message])
        add_sig(:sig => 'banmask list', :method => :mask_list, :group => admin, :desc => 'List all currently active banmasks')
        add_sig(:sig => 'banmask remove (\d+)', :method => :mask_remove, :group => admin, :desc => 'Remove a currently enabled ban mask', :params => [:id])
        add_sig(:sig => 'banlist', :method => :ban_list, :group => admin, :desc => 'List all currently active bans generated from the bot')
        add_sig(:sig => 'banlist remove (\d+)', :method => :ban_remove, :group => admin, :desc => 'Remove a current ban', :params => [:id])
        add_sig(:sig => 'exempt mode ([ov]) ?(\S+)?', :method => :exempt_mode, :group => admin, :desc => 'Exempt given modes from kick. Apply to all channels if one is not provided', :params => [:mode, :channel])
        add_sig(:sig => 'exempt nick (\S+) ?(\S+)?', :method => :exempt_nick, :group => admin, :desc => 'Exempt a nick from kicks globally or per channel', :params => [:nick, :channel])
        add_sig(:sig => 'exempt source (\S+)', :method => :exempt_source, :group => admin, :desc => 'Exempt a source from kicks globally or per channel', :params => [:source, :channel])
        add_sig(:sig => 'exempt list (nick|mode|source)', :method => :exempt_list, :group => admin, :desc => 'List current exemptions of given type', :params => [:type])
        add_sig(:sig => 'exempt remove (nick|mode|source) (\d+)', :method => :exempt_remove, :group => admin, :desc => 'Remove exemption from given type', :params => [:type, :id])
        @pipeline.hook(self, :mode_check, ModSpox::Messages::Incoming::Mode)
        @pipeline.hook(self, :join_check, ModSpox::Messages::Incoming::Join)
        @pipeline.hook(self, :who_check, ModSpox::Messages::Incoming::Who)
        @pipeline.hook(self, :process_ban, 'Banner::Ban')
        BanRecord.create_table unless BanRecord.table_exists?
        BanMask.create_table unless BanMask.table_exists?
        BanNickExempt.create_table unless BanNickExempt.table_exists?
        BanModeExempt.create_table unless BanModeExempt.table_exists?
        BanSourceExempt.create_table unless BanSourceExempt.table_exists?
        load_timer
        @time = Object::Time.now
    end

    def destroy
        reset_time
    end

    def process_ban(message)
        ban(message.nick, message.channel, message.time, message.message, message.invite?, message.display_time?)
    end

    def reset_time
        elapsed = Object::Time.now.to_i - @time.to_i
        BanRecord.filter('remaining > 0').update("remaining = remaining - #{elapsed}")
        BanMask.filter('bantime > 0').update("bantime = bantime - #{elapsed}")
        @time = Object::Time.now
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Perform a simple ban with default values
    def default_ban(message, params)
        params[:time] = 86400
        params[:channel] = message.target.name
        full_ban(message, params)
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Ban given nick in given channel
    def channel_ban(message, params)
        params[:time] = 86400
        full_ban(message, params)
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Ban nick in given channel for given time providing given message
    def full_ban(message, params)
        nick = Helpers.find_model(params[:nick], false)
        channel = Channel.locate(params[:channel])
        if(!me.is_op?(channel))
            reply(message.replyto, "Error: I'm not a channel operator")
        elsif(!nick)
            reply(message.replyto, "#{message.source.nick}: Failed to find nick #{params[:nick]}")
        elsif(!channel)
            reply(message.replyto, "#{message.source.nick}: Failed to find channel #{params[:channel]}")
        else
            ban(nick, channel, params[:time], params[:message])
        end
    end

    # nick:: ModSpox::Models::Nick to ban
    # channel:: ModSpox::Models::Channel to ban nick from
    # time:: number of seconds ban should last
    # reason:: reason for the ban
    # invite:: invite nick back to channel when ban expires
    # show_time:: show ban time in kick message
    def ban(nick, channel, time, reason, invite=false, show_time=true)
        raise Exceptions::InvalidType.new("Nick given is not a nick model") unless nick.is_a?(Models::Nick)
        raise Exceptions::InvalidType.new("Channel given is not a channel model") unless channel.is_a?(Models::Channel)
        if(!me.is_op?(channel))
            raise NotOperator.new("I am not an operator in #{channel.name}")
        elsif(!nick.channels.include?(channel))
            raise NotInChannel.new("#{nick.nick} is not in channel: #{channel.name}")
        elsif(check_exempt(nick, channel))
            raise BanExemption.new("This nick is exempt from bans: #{nick.nick}")
        else
            reset_time
            mask = nick.address.nil? || nick.address.empty? ? "#{nick.nick}!*@*" : "*!*@#{nick.address}"
            record = BanRecord.filter(:nick_id => nick.pk, :channel_id => channel.pk, :mask => mask, :removed => false).first
            if(record)
                record.bantime = record.bantime + time.to_i
                record.remaining = record.remaining + time.to_i
                record.save
            else
                record = BanRecord.new(:nick_id => nick.pk, :bantime => time.to_i, :remaining => time.to_i, :stamp => ::Time.now,
                    :invite => invite, :channel_id => channel.pk, :mask => mask)
                record.save
            end
            @pipeline << Messages::Internal::TimerAdd.new(self, record.remaining, nil, true){ clear_record(record.pk, record.remaining) }
            reset_time
            message = reason ? reason : 'no soup for you!'
            message = "#{message} (Duration: #{Helpers.format_seconds(time.to_i)})" if show_time
            @pipeline << ChannelMode.new(channel, '+b', mask)
            @pipeline << Kick.new(nick, channel, message)
        end
    end

    # mask:: mask to match against source (Regexp)
    # channel:: ModSpox::Models::Channel to ban from
    # message:: kick message
    # time:: time ban on mask should stay in place
    # Bans all users who's source matches the given mask
    def mask_ban(mask, channel, message, time)
        raise NotInChannel.new("I am not in channel: #{channel.name}") unless me.channels.include?(channel)
        reset_time
        record = BanMask.new(:mask => mask, :channel_id => channel.pk, :message => message, :bantime => time.to_i, :stamp => Object::Time.now)
        record.save
        check_masks
        @pipeline << Messages::Internal::TimerAdd.new(self, record.bantime, nil, true){ record.destroy }
        reset_time
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Set a ban on any nick with a source match given regex
    def message_mask_ban(message, params)
        channel = params[:channel] ? Channel.filter(:name => params[:channel]).first : message.target
        if(channel)
            begin
                mask_ban(params[:mask], channel, params[:message], params[:time])
                reply(message.replyto, "Okay")
            rescue Object => boom
                reply(message.replyto, "Error: Failed to ban mask. Reason: #{boom}")
                Logger.warn("ERROR: #{boom} #{boom.backtrace.join("\n")}")
            end
        else
            reply(message.replyto, "Error: No record of channel: #{params[:channel]}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # List all ban masks
    def mask_list(message, params)
        if(BanMask.all.size > 0)
            reply(message.replyto, "Masks currently banned:")
            BanMask.all.each do |mask|
                reply(message.replyto, "\2ID:\2 #{mask.pk} \2Mask:\2 #{mask.mask} \2Time:\2 #{Helpers.format_seconds(mask.bantime.to_i - (Object::Time.now.to_i - @time.to_i))} \2Channel:\2 #{mask.channel.name}")
            end
        else
            reply(message.replyto, "No ban masks currently enabled")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Remove ban mask with given ID
    def mask_remove(message, params)
        mask = BanMask[params[:id].to_i]
        if(mask)
            mask.destroy
            reply(message.replyto, 'Okay')
        else
            reply(message.replyto, "\2Error:\2 Failed to find ban mask with ID: #{params[:id]}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # List all currently active bans originating from the bot
    def ban_list(message, params)
        set = BanRecord.filter(:removed => false)
        if(set.count > 0)
            reply(message.replyto, "Currently active bans:")
            set.each do |record|
                remains = record.remaining.to_i - (Object::Time.now.to_i - @time.to_i)
                remains = 0 unless remains > 0
                reply(message.replyto, "\2ID:\2 #{record.pk} \2Nick:\2 #{record.nick.nick} \2Channel:\2 #{record.channel.name} \2Initial time:\2 #{Helpers.format_seconds(record.bantime.to_i)} \2Time remaining:\2 #{Helpers.format_seconds(remains)}")
            end
        else
            reply(message.replyto, "No bans currently active")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Remove given ban
    def ban_remove(message, params)
        record = BanRecord[params[:id].to_i]
        if(record)
            clear_record(record.pk, nil)
        else
            reply(message.replyto, "\2Error:\2 Failed to find ban record with ID: #{params[:id]}")
        end
    end

    # Check all enabled ban masks and ban any matches found
    def check_masks
        masks = BanMask.map_masks
        masks.keys.each do |channel_name|
            channel = Channel.filter(:name => channel_name).first
            if(me.is_op?(channel))
                channel.nicks.each do |nick|
                    match = nil
                    masks[channel.name].each do |mask|
                        if(nick.source =~ /#{mask[:mask]}/)
                            match = mask if match.nil? || mask[:bantime].to_i > match[:bantime].to_i
                        end
                    end
                    unless match.nil?
                        begin
                            ban(nick, channel, match[:bantime], match[:message])
                        rescue Object => boom
                            Logger.warn("Mask based ban failed. Reason: #{boom}")
                        end
                    end
                end
            else
                Logger.info("Ban masks will not be processed due to lack of operator status")
            end
        end
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Check if the nick in the channel matches any ban masks
    def mask_check(nick, channel)
        return unless me.is_op?(channel)
        match = nil
        BanMask.filter(:channel_id => channel.pk).each do |bm|
            if(nick.source =~ /#{bm.mask}/)
                match = bm if match.nil? ||  match.bantime < bm.bantime
            end
        end
        unless(match.nil?)
            begin
                ban(nick, channel, match.bantime, match.message)
            rescue Object => boom
                Logger.warn("Mask based ban failed. Reason: #{boom}")
            end
        end
    end

    # message:: ModSpox::Messages::Incoming::Mode
    # Check for mode changes. Remove pending ban removals if
    # done manually
    def mode_check(message)
        if(message.target.is_a?(String) && message.source != me)
            if(message.mode == '-b')
                BanRecord.filter(:mask => message.target, :channel_id => message.channel.pk).each do |match|
                    match.remaining = 0
                    match.removed = true
                    match.save
                end
            end
        end
        if(message.target == me && message.mode == '+o')
            check_masks
            BanRecord.filter('remaining < 1 AND removed = ?', false).each do |record|
                clear_record(record.pk, nil)
            end
        end
    end

    # message:: ModSpox::Messages::Incoming::Join
    # Check is nick is banned
    def join_check(message)
        mask_check(message.nick, message.channel)
    end

    # message:: ModSpox::Messages::Incoming::Who
    # Check if we updated any addresses
    def who_check(message)
        check_masks
    end

    def load_timer
        BanRecord.filter('removed = ? AND remaining > 0', false).each do |record|
            @pipeline << Messages::Internal::TimerAdd.new(self, record.remaining, nil, true){ clear_record(record.pk, record.remaining) }
        end
        BanMask.filter('bantime > 0').each do |record|
            @pipeline << Messages::Internal::TimerAdd.new(self, record.bantime, nil, true){ record.destroy }
        end
    end

    def clear_record(id, slept=nil)
        record = BanRecord[id]
        return if !record || record.removed
        if(!slept.nil? && (record.remaining - slept).to_i > 0)
            record.remaining = record.remaining - slept
        else
            record.remaining = 0
            if(me.is_op?(record.channel))
                @pipeline << ChannelMode.new(record.channel, '-b', record.mask)
                record.removed = true
                @pipeline << Invite.new(record.nick, record.channel) if record.invite
            end
        end
        record.save
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Add ban exemption for a given mode
    def exempt_mode(message, params)
        response = nil
        if(params[:channel])
            channel = Helpers.find_model(params[:channel])
            if(channel.is_a?(Models::Channel))
                BanModeExempt.find_or_create(:channel_id => channel.pk, :mode => params[:mode])
                response = 'Mode exemption has been added'
            else
                response = "Failed to find given channel: #{params[:channel]}"
            end
        else
            BanModeExempt.find_or_create(:channel_id => nil, :mode => params[:mode])
            response = 'Mode exemption has been added'
        end
        reply message.replyto, response
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Add ban exemption for a given nick
    def exempt_nick(message, params)
        response = ''
        nick = Helpers.find_model(params[:nick])
        unless(nick.is_a?(Models::Nick))
            reply message.replyto, "\2Error:\2 Failed to find record of: #{params[:nick]}"
            return
        end
        channel = params[:channel] ? Helpers.find_model(params[:channel]) : nil
        if(channel)
            if(channel.is_a?(Models::Channel))
                BanNickExempt.find_or_create(:channel_id => channel.pk, :nick_id => nick.pk)
                response = "Nick exemption for \2#{params[:nick]}\2 has been added to channel: \2#{params[:channel]}\2"
            else
                response = "Failed to find given channel: #{params[:channel]}"
            end
        else
            BanNickExempt.find_or_create(:nick_id => nick.pk)
            response = "Nick exemption for \2#{params[:nick]}\2 has been added for all channels"
        end
        reply message.replyto, response
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Add ban exemption for sources matching a given mask
    def exempt_source(message, params)
        channel = params[:channel] ? Helpers.find_model(params[:channel]) : nil
        response = ''
        if(channel)
            if(channel.is_a?(Models::Channel))
                BanSourceExempt.find_or_create(:channel_id => channel.pk, :source => params[:source])
                reponse = "Added exempt source: #{params[:source]} to channel: #{params[:channel]}"
            else
                response = "Failed to find given channel: #{params[:channel]}"
            end
        else
            BanSourceExempt.find_or_create(:channel_id => nil, :source => params[:source])
            response = "Added global exemption for source: #{params[:source]}"
        end
        reply message.replyto, response
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # List given type of current ban exemptions
    def exempt_list(message, params)
        output = []
        if(params[:type] == 'nick')
            output << 'Current nick exemptions:'
            BanNickExempt.all.each do |record|
                if(record.channel)
                    output << "\2#{record.pk}:\2 \2#{record.nick.nick}\2 is exempt in \2#{record.channel.name}\2"
                else
                    output << "\2#{record.pk}:\2 \2#{record.nick.nick}\2 is exempt in \2all\2 channels"
                end
            end
        elsif(params[:type] == 'mode')
            output << 'Current mode exemptions:'
            BanModeExempt.all.each do |record|
                mode = record.mode == 'o' ? 'operator' : 'voice'
                if(record.channel)
                    output << "\2#{record.pk}:\2 mode: \2#{mode}\2 is exempt in \2#{record.channel.name}\2"
                else
                    output << "\2#{record.pk}:\2 mode: \2#{mode}\2 is exempt in \2all\2 channels"
                end
            end
        elsif(params[:type] == 'source')
            output << 'Current source exemptions:'
            BanSourceExempt.all.each do |record|
                if(record.channel)
                    output << "\2#{record.pk}:\2 sources matching: #{record.source} are exempt in \2#{record.channel.name}\2"
                else
                    output << "\2#{record.pk}:\2 sources matching: #{record.source} are exempt in \2all\2 channels"
                end
            end
        end
        reply message.replyto, output
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: parameters
    # Remove given exemption from given list
    def exempt_remove(message, params)
        response = 'Exemption has been removed'
        record = nil
        case params[:type]
            when 'nick'
                record = BanNickExempt[params[:id].to_i]
            when 'mode'
                record = BanModeExempt[params[:id].to_i]
            when 'source'
                record = BanSourceExempt[params[:id].to_i]
        end
        if(record)
            record.destroy
        else
            response = "Failed to find exemption of type: #{params[:type]} with ID: #{params[:id]}"
        end
        reply message.replyto, response
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Check if nick is currently exempt from bans
    def check_exempt(nick, channel)
        return true unless BanNickExempt.filter('nick_id = ? AND (channel_id = ? OR channel_id is null)', nick.pk, channel.pk).first.nil?
        return true if !BanModeExempt.filter("mode = 'o' AND (channel_id = ? OR channel_id is null)", channel.pk).first.nil? && nick.is_op?(channel)
        return true if !BanModeExempt.filter("mode = 'v' AND (channel_id = ? OR channel_id is null)", channel.pk).first.nil? && nick.is_voice?(channel)
        BanSourceExempt.filter('channel_id = ? OR channel_id is null', channel.pk).each do |record|
            regex = Regexp.new(record.source)
            return true unless regex.match(nick.source).nil?
        end
        return false
    end

    class BanRecord < Sequel::Model
        many_to_one :channel, :class => ModSpox::Models::Channel
        many_to_one :nick, :class => ModSpox::Models::Nick

        def before_create
            stamp = Object::Time.now
        end
    end

    class BanMask < Sequel::Model
        many_to_one :channel, :class => ModSpox::Models::Channel

        def self.map_masks
            masks = {}
            BanMask.all.each do |mask|
                Logger.info("Processing mask for channel: #{mask.channel.name}")
                masks[mask.channel.name] = [] unless masks.has_key?(mask.channel.name)
                masks[mask.channel.name] << {:mask => mask.mask, :message => mask.message, :bantime => mask.bantime, :channel => mask.channel}
            end
            return masks
        end
    end

    class BanNickExempt < Sequel::Model
        many_to_one :nick, :class => ModSpox::Models::Nick
        many_to_one :channel, :class => ModSpox::Models::Channel
    end

    class BanSourceExempt < Sequel::Model
        many_to_one :channel, :class => ModSpox::Models::Channel

        def mask
            return values[:source] ? Marshal.load(values[:source].unpack('m')[0]) : nil
        end

        def mask=(val)
            update(:source => [Marshal.dump(val)].pack('m'))
        end

    end

    class BanModeExempt < Sequel::Model
        many_to_one :channel, :class => ModSpox::Models::Channel
    end

    class NotOperator < Exceptions::BotException
    end

    class NotInChannel < Exceptions::BotException
    end

    class BanExemption < Exceptions::BotException
    end

    class Ban
        # Nick to be kicked
        attr_reader :nick
        # Channel to be kicked from
        attr_reader :channel
        # Type of ban: :ban, :kick, :kickban
        attr_reader :type
        # Ban time (0 for no ban)
        attr_reader :time
        # Message to display in kick
        attr_reader :message
        def initialize(nick, channel, type=:kickban, message=nil, time=30, invite=false, display_time=false)
            @nick = nick
            @channel = channel
            raise ModSpox::Exceptions::InvalidType.new('Ban requires a valid type (:ban, :kick, :kickban)') unless [:kick, :ban, :kickban].include?(type)
            @type = type
            @time = time.to_i
            @message = message
            @display_time = display_time ? true : false
            @invite = invite ? true : false
        end

        # Display ban time in kick message
        def display_time?
            return @display_time
        end

        # Invite user to channel after ban expiration
        def invite?
            return @invite
        end
    end

end