class Bytes < ModSpox::Plugin
    include Models
    def initialize(args)
        super
        Signature.find_or_create(:signature => 'bytes (\d+)', :plugin => name, :method => 'convert',
            :description => 'Convert bytes to human readable string').params = [:bytes]
    end
    
    def convert(message, params)
        reply message.replyto, "#{params[:bytes]} is roughly #{Helpers.format_size(params[:bytes].to_i)}"
    end
end