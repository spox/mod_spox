class Helper < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super(pipeline)
        add_sig(:sig => 'help', :method => :default_help, :desc => 'Display default help information')
        add_sig(:sig => 'help (\S+)', :method => :plugin_help, :desc => 'Display help information from given plugin', :params => [:plugin])
    end

    def default_help(message, params)
        plugins = Signature.select(:plugin).map(:plugin)
        plugins.uniq!
        reply message.replyto, "Plugins currently available for help: #{plugins.sort.join(', ')}"
        reply message.replyto, "Request help on a plugin: #{Models::Trigger.filter(:active => true).first.trigger}help Plugin"
    end

    def plugin_help(message, params)
        sigs = []
        Signature.all.each{|s| sigs << s if s.plugin.downcase == params[:plugin].downcase}
        if(sigs.size > 0)
            output = []
            output << "Available triggers for plugin: \2#{params[:plugin]}\2"
            sigs.each do |sig|
                help = []
                help << "\2Pattern:\2 #{sig.signature}"
                help << "\2Parameters:\2 [#{sig.params.join(' | ')}]" if sig.params
                help << "\2Auth Group:\2 #{Group[sig.group_id].name}" if sig.group_id
                help << "\2Description:\2 #{sig.description}" if sig.description
                help << "\2Requirement:\2 #{['public', 'private'].include?(sig.requirement) ? sig.requirement : 'both'}"
                output << help.join(' ')
            end
            if(message.is_dcc?)
                reply message.replyto, output
            else
                reply message.source, output
            end
        else
            Signature.all.each{|s| sigs << s.plugin if /#{s.signature.gsub(/(\s|\().*$/, '')}/ =~ params[:plugin]}
            if(sigs.count > 0)
                sigs.uniq!
                reply message.replyto, "Possible plugin matches for \2#{params[:plugin]}\2: #{sigs.sort.join(', ')}"
            else
                reply message.replyto, "\2Error:\2 No triggers found for plugin named: #{params[:plugin]}"
            end
        end
    end

end