require 'net/http'
require 'rexml/document'

class FML < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'fml( (love|money|kids|work|health|sex|miscellaneous))?', :method => :random, :desc => 'Fuck my life', :params => [:wspace, :category])
        @site = 'http://api.betacie.com/view/'
        @vars = ['key=readonly', 'language=en']
    end
    
    def random(m, params)
        begin
            t = params[:category] ? "#{params[:category].strip}/" : ''
            reply m.replyto, get_text("#{t}random")
        rescue Object => boom
            error m.replyto, 'Failed to fetch.' + boom.to_s
        end
    end
    
    private
    
    def get_text(thing)
        data = Net::HTTP.get_response(URI.parse(@site+thing+'?'+@vars.join('&'))).body
        doc = REXML::Document.new(data)
        output = []
        doc.elements.each('root/items/item/text') do |t|
            output << Helpers.convert_entities(t.text)
        end
        raise 'Failed to fetch item from FML' if output.empty?
        return output[rand(output.size)]
    end

end