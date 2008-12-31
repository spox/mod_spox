class NickServ < ModSpox::Plugin

    #TODO: Add support for things like RECOVERY and GHOST

    def initialize(pipeline)
        super
        admin = Models::Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'nickserv address( \S+)?', :method => :set_address, :group => admin,
            :desc => 'Set/view address to send nickserv info to', :params => [:address])
        add_sig(:sig => 'nickserv combo (\S+) (\S+)', :method => :set_combo, :group => admin,
            :desc => 'Set nick/pass combo', :params => [:nick, :password], :req => 'private')
        add_sig(:sig => 'nickserv show', :method => :output_info, :group => admin,
            :desc => 'Show nickserv info', :req => 'private')
        add_sig(:sig => 'nickserv send', :method => :send_combo, :group => admin,
            :desc => 'Send nickserv info')
        @nickserv = Models::Setting.find_or_create(:name => 'nickserv').value
        unless(@nickserv.is_a?(Hash) && @nickserv.has_key?(:address) && @nickserv.has_key?(:combos))
            @nickserv = {:address => nil, :combos => {}}
        end
        @pipeline.hook(self, :send_nickserv, :Incoming_Welcome)
    end
    
    # @nickserv = {:address => 'nickserv@blah', :combos => {'nick' => 'pass'}}
    
    def set_address(message, params)
        if(params[:address])
            params[:address].strip!
            @nickserv[:address] = params[:address]
            save_info
            reply message.replyto, "Nickserv address updated to: #{params[:address]}"
        else
            unless(@nickserv[:address].nil?)
                reply message.replyto, "Nickserv address set to: #{@nickserv[:address]}"
            else
                reply message.replyto, "\2Error:\2 Nickserv address has not been set"
            end
        end 
    end
    
    def set_combo(message, params)
        @nickserv[:combos][params[:nick].to_sym] = params[:password]
        save_info
        reply message.replyto, "Nickserv password saved for nick: \2#{params[:nick]}\2"
    end
    
    def output_info(message, params)
        output = ["\2Nickserv information dump:\2"]
        output << "Address used to send identification: #{@nickserv[:address].nil? ? 'unset' : @nickserv[:address]}"
        @nickserv[:combos].each_pair{|k,v| output << "#{k} -> #{v}"}
        reply message.replyto, output
    end
    
    def send_combo(message, params)
        output = 'Identification sent to nickserv'
        begin
            identify
        rescue Object => boom
            output = boom.to_s
        ensure
            reply message.replyto, output
        end
    end
    
    def send_nickserv(m)
        identify
    end
    
    private
    
    def save_info
        s = Models::Setting.filter(:name => 'nickserv').first.update(:value => @nickserv)
    end
    
    def identify
        raise Exceptions::BotException.new('No address set for nickserv') if @nickserv[:address].nil?
        if(@nickserv[:combos].has_key?(me.nick.to_sym))
            @pipeline << Messages::Outgoing::Privmsg.new(@nickserv[:address], "IDENTIFY #{@nickserv[:combos][me.nick.to_sym]}")
        else
            raise Exceptions::BotException.new("No nickserv password available for: #{me.nick.nick}")
        end
    end

end