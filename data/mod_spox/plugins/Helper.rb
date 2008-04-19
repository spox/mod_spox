class Helper < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super(pipeline)
        Signature.find_or_create(:signature => 'help', :plugin => name, :method => 'default_help',
            :description => 'Display default help information')
        Signature.find_or_create(:signature => 'help (\S+)', :plugin => name, :method => 'plugin_help',
            :description => 'Display help information from given plugin').params = [:plugin]
    end
    
    def default_help(message, params)
        plugins = Signature.map(:plugin)
        plugins.uniq!
        reply message.replyto, "Plugins currently available for help: #{plugins.join(', ')}"
        reply message.replyto, "Request help on a plugin: !help Plugin"
    end
    
    def plugin_help(message, params)
        sigs = Signature.filter(:plugin => params[:plugin])
        if(sigs.count > 0)
            reply message.source, "Available triggers for plugin: \2#{params[:plugin]}\2"
            sigs.each do |sig|
                reply message.source, "\2Pattern:\2 #{sig.signature} \2Parameters:\2 [#{sig.params.join(' | ')}] \2Description:\2 #{sig.description}"
            end
        else
            reply message.replyto, "\2Error:\2 No triggers found for plugin named: #{params[:plugin]}"
        end
    end

end