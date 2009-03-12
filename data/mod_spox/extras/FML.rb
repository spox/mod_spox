require 'net/http'
require 'rexml/document'

class FML < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'fml', :method => :random, :desc => 'Fuck my life')
        @site = 'http://api.betacie.com/view/'
        @vars = ['key=readonly', 'language=en']
    end
    
    def random(m, params)
        begin
            reply m.replyto, get_text('random')
        rescue Object => boom
            error m.replyto, 'Failed to fetch.' + boom.to_s
        end
    end
    
    private
    
    def get_text(thing)
        data = Net::HTTP.get_response(URI.parse(@site+thing+'?'+@vars.join('&'))).body
        doc = REXML::Document.new(data)
        output = nil
        doc.elements.each('root/items/item/text') do |t|
            output = t.text
        end
        raise 'Failed to fetch item from FML' if output.nil?
        return output
    end

end