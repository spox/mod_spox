class Bytes < ModSpox::Plugin
    include Models
    def initialize(args)
        super
        add_sig(:sig => 'bytes (\d+)', :method => :convert, :desc => 'Convert bytes to human readable string', :params => [:bytes])
    end
    
    def convert(message, params)
        reply message.replyto, "#{params[:bytes]} is roughly #{Helpers.format_size(params[:bytes].to_i)}"
    end
end