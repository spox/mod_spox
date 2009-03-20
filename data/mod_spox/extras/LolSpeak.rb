# IMPORTANT NOTE: This plugin requires installation of the LOLSpeak gem
class LolSpeak < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        begin
            require 'lolspeak'
        rescue Object => boom
            Logger.warn('Error: This plugins requires the lolspeak gem. Please install gem and reload plugin.')
            raise BotException.new("Failed to initialize plugin. Missing lolspeak gem.")
        end
        add_sig(:sig => 'lolspeak (.+)', :method => :translate, :desc => 'Translate text to lolspeak', :params => [:text])
    end
    
    def translate(message, params)
        reply message.replyto, "\2lulz:\2 #{params[:text].to_lolspeak}"
    end
    
end