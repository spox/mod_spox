class Authenticator < ModSpox::Plugin
    def initialize(pipeline)
        super(pipeline)
        group = Models::Group.filter(:name => 'admin').first
        Models::Signature.find_or_create(:signature => 'auth (\S+)', :plugin => name, :method => 'authenticate',
            :description => 'Authenticate with bot using a password').params = [:password]
        Models::Signature.find_or_create(:signature => 'ident', :plugin => name, :method => 'send_whois',
            :description => 'Instructs the bot to check your NickServ status')
        Models::Signature.find_or_create(:signature => 'auth mask add (\S+) (\S+)', :plugin => name, :method => 'add_mask',
            :group_id => group.pk, :description => 'Add authentication mask and set initial group').params = [:mask, :group]
        Models::Signature.find_or_create(:signature => 'auth mask set (\d+) (.+)', :plugin => name, :method => 'set_mask_groups',
            :group_id => group.pk, :description => 'Set groups for the given mask').params = [:id, :groups]
        Models::Signature.find_or_create(:signature => 'auth mask unset (\d+) (.+)', :plugin => name, :method => 'del_mask_groups',
            :group_id => group.pk, :description => 'Remove groups for the given mask').params = [:id, :groups]
        Models::Signature.find_or_create(:signature => 'auth mask remove (\d+)', :plugin => name, :method => 'remove_mask',
            :group_id => group.pk, :description => 'Remove authentication mask').params = [:id]
        Models::Signature.find_or_create(:signature => 'auth mask list', :plugin => name, :method => 'list_mask',
            :group_id => group.pk, :description => 'List all available authentication masks')
        Models::Signature.find_or_create(:signature => 'auth nick ident (\S+) (true|false)', :plugin => name, :method => 'nick_ident',
            :group_id => group.pk, :description => 'Allow authentication to nicks identified to NickServ').params = [:nick, :ident]
        Models::Signature.find_or_create(:signature => 'auth nick password (\S+) (\S+)', :plugin => name, :method => 'nick_pass',
            :group_id => group.pk, :description => 'Set authentication password for nick').params = [:nick, :password]
        Models::Signature.find_or_create(:signature => 'auth nick clear password (\S+)', :plugin => name, :method => 'clear_pass',
            :group_id => group.pk, :description => 'Clear nicks authentication password').params = [:nick]
        Models::Signature.find_or_create(:signature => 'auth nick info (\S+)', :plugin => name, :method => 'nick_info',
            :group_id => group.pk, :description => 'Return authentication information about given nick').params = [:nick]
        Models::Signature.find_or_create(:signature => 'auth nick set (\S+) (\S+)', :plugin => name, :method => 'set_nick',
            :group_id => group.pk, :description => 'Set the group for a given nick').params = [:nick, :group]
        Models::Signature.find_or_create(:signature => 'auth nick unset (\S+) (\S+)', :plugin => name, :method => 'unset_nick',
            :group_id => group.pk, :description => 'Unset the group for a given nick').params = [:nick, :group]
        Models::Signature.find_or_create(:signature => 'auth group list', :plugin => name, :method => 'list_groups',
            :group_id => group.pk, :description => 'List available authentication groups')
        Models::Signature.find_or_create(:signature => 'auth group info (\S+)', :plugin => name, :method => 'group_info',
            :group_id => group.pk, :description => 'List members of given group').params = [:group]
        Models::Signature.find_or_create(:signature => 'groups', :plugin => name, :method => 'show_groups',
            :description => 'Show user groups they are currently a member of')
        @whois_cache = []
        @nickserv_nicks = []
        populate_nickserv
        @pipeline.hook(self, :check_join, :Incoming_Join)
        @pipeline.hook(self, :check_nicks, :Incoming_Who)
        @pipeline.hook(self, :check_nicks, :Incoming_Names)
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Authenticate a user by password
    def authenticate(message, params)
        return unless message.is_private?
        if(message.is_private? && message.source.auth.check_password(params[:password]))
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, 'Authentication was successful')
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, 'Authentication failed')
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Add an authentication mask
    def add_mask(message, params)
        begin
            group = Models::Group.filter(:name => params[:group]).first
            raise Exception.new("Failed to find group") unless group
            a = Models::Auth.find_or_create(:mask => Regexp.new(params[:mask]).source)
            a.group = group
            a.save
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, 'Mask has been successfully added to authentication table')
        rescue Object => boom
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Authentication failed to add mask. Reason: #{boom}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Add an authentication group to a given mask
    def set_mask_groups(message, params)
        auth = Models::Auth[params[:id]]
        if(auth)
            params[:groups].split(/\s/).each do |g|
                group = Models::Group.filter(:name => g).first
                auth.group = group if group
            end
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Mask groups have been updated")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find mask with ID: #{params[:id]}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Remove an authentication group from a given mask
    def del_mask_groups(message, params)
        auth = Models::Auth[params[:id]]
        if(auth)
            params[:groups].split(/\s/).each do |g|
                group = Models::Group.filter(:name => g).first
                auth.remove_group(group) if group
            end
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Mask groups have been updated")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find mask with ID: #{params[:id]}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # List all authentication masks
    def list_mask(message, params)
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, 'Authentication Mask Listing:')
        auths = []
        Models::Auth.where('mask is not null').each{|a| auths << a}
        auths.each do |a|
            groups = []
            a.groups.each{|g| groups << g.name}
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "\2ID:\2 #{a.pk}: \2mask:\2 #{a.mask} \2groups:\2 #{groups.join(', ')}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Remove given authentication mask
    def remove_mask(message, params)
        auth = Models::Auth[params[:id].to_i]
        if(auth)
            auth.destroy
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Authentication mask with ID #{params[:id]} was deleted")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "\2Failed\2: Could not find an authentication mask with ID: #{params[:id]}")
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Set nick authentication by NickServ
    def nick_ident(message, params)
        nick = Models::Nick.locate(params[:nick])
        if(params[:ident] == 'true')
            nick.auth.update_with_params(:services => true)
        else
            nick.auth.update_with_params(:services => false)
        end
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Nick #{params[:nick]} has been updated. Services for authentication has been set to #{params[:ident]}")
    end


    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Set password for given nick
    def nick_pass(message, params)
        nick = Models::Nick.locate(params[:nick])
        nick.auth.password = params[:password]
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Nick #{params[:nick]} has been updated. Password has been set.")
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Clear password field for given nick
    def clear_pass(message, params)
        nick = Models::Nick.locate(params[:nick])
        nick.auth.password = nil
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Nick #{params[:nick]} has been updated. Password has been unset.")
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Display info for given nick
    def nick_info(message, params)
        nick = Helpers.find_model(params[:nick], false)
        if(nick)
            info = []
            info << "\2INFO [#{nick.nick}]:\2"
            groups = []
            Models::AuthGroup.filter(:auth_id => nick.auth.pk).each do |ag|
                groups << ag.group.name
            end
            info << "Groups: #{groups.uniq.sort.join(', ')}."
            nick.auth.password.nil? ? info << 'Password has not been set.' : info << 'Password has been set.'
            nick.auth.services ? info << 'Nickserv ident is enabled.' : info << 'Nickserv ident is disabled.'
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "#{info.join(' ')}")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "I have no record of nick: #{params[:nick]}")
        end
    end

    def show_groups(message, params)
        groups = []
        message.source.auth_groups.each{|g| groups << g.name}
        if(groups.empty?)
            reply message.replyto, "You are not currently a member of any groups"
        else
            reply message.replyto, "\2Groups (#{message.source.nick}):\2 #{groups.join(', ')}"
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Add given nick to authentication group
    def set_nick(message, params)
        group = Models::Group.filter(:name => params[:group]).first
        nick = Models::Nick.locate(params[:nick])
        if(group)
            nick.auth.group = group
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Nick #{params[:nick]} has been added to the group: #{params[:group]}")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find authentication group: #{params[:group]}")

        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Remove given nick from authenticationg group
    def unset_nick(message, params)
        group = Models::Group.filter(:name => params[:group]).first
        nick = Helpers.find_model(params[:nick], false)
        if(group && nick)
            nick.remove_group(group)
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Removed #{params[:nick]} from the #{params[:group]} authentication group.")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find nick: #{params[:nick]}") unless nick
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find group: #{params[:group]}") unless group
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Send WHOIS for nick
    def send_whois(message, params)
        message.source.clear_auth
        @pipeline << Messages::Outgoing::Whois.new(message.source.nick)
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Display all available authentication groups
    def list_groups(message, params)
        groups = []
        Models::Group.all.each{|g| groups << g.name}
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "\2Groups:\2 #{groups.join(', ')}")
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: Signature parameters
    # Display info about given group
    def group_info(message, params)
        group = Models::Group.filter(:name => params[:group]).first
        if(group)
            nicks = []
            masks = []
            Models::AuthGroup.filter(:group_id => group.pk).each do |ag|
                if(ag.auth.nick)
                    nicks << ag.auth.nick.nick
                end
                if(ag.auth.mask)
                    masks << ag.auth.mask
                end
            end
            output = []
            output << "\2Nicks:\2 #{nicks.join(', ')}" if nicks.size > 0
            output << "\2Masks:\2 #{masks.join(' | ')}" if masks.size > 0
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "\2Group #{params[:group]}:\2 #{output.join('. ')}")
        else
            @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "Failed to find group named: #{params[:group]}")
        end
    end

    # Populates array with nicks that authenticate by nickserv
    def populate_nickserv
        Models::Auth.filter('services = ?', true).each do |auth|
            @nickserv_nicks << auth.nick.nick.downcase
        end
    end

    def check_nickserv(nick)
        if(@nickserv_nicks.include?(nick.nick.downcase))
            if(!nick.auth.authed && !@whois_cache.include?(nick.nick.downcase))
                @pipeline << Messages::Outgoing::Whois.new(nick)
                @whois_cache << nick.nick.downcase
            end
        end
    end

    def check_join(message)
        if(@nickserv_nicks.include?(nick.nick.downcase))
            @pipeline << Messages::Outgoing::Whois.new(message.nick) unless message.nick == me
        end
    end

    def check_nicks(message)
        message.nicks.each{|nick| check_nickserv(nick) }
    end

end