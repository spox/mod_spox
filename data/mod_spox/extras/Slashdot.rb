require 'rexml/document'
require 'open-uri'

class Slashdot < ModSpox::Plugin

    def initialize(pipeline)
        begin
            require 'htmlentities'
        rescue Object => boom
            Logger.warn('Error: This plugin requires the HTMLEntities gem. Please install and reload plugin.')
            raise Exceptions::BotException.new("Missing required HTMLEntities library")
        end
        super
        add_sig(:sig => '(slashdot|\/\.) ?(\d+)?', :method => 'show_slashdot', :desc => 'Slashdot headlines', :params => [:trig, :num])
        @coder = HTMLEntities.new
    end

    def show_slashdot(message, params)
        src = open('http://rss.slashdot.org/Slashdot/slashdot')
        doc = REXML::Document.new(src.read)
        num = params[:num].nil? || params[:num].to_i < 1 ? 1 : params[:num].to_i
        num = 5 if num > 5
        output = []
        doc.elements.each('rdf:RDF/item') do |item|
            num -= 1
            title = CGI::unescapeHTML(item.elements['title'].text)
            title = title.gsub(/<.+?>/, ' ').gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
            title = @coder.decode(title)
            output << "\2/.\2 #{title} \2->\2 #{Helpers.tinyurl(item.elements['link'].text)}"
            break if num < 1
        end
        reply message.replyto, output
    end

end