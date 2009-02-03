require 'net/http'
require 'open-uri'
require 'cgi'
class Search < ModSpox::Plugin

    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        add_sig(:sig => 'search count (.+)', :method => 'search_count', :params => [:terms], :desc => 'Show number of results for given search')
        Models::Signature.find_or_create(:signature => 'search (?!count)(\d+)? ?(.+)', :plugin => name, :method => 'search', :description => 'Search the internet').params = [:number, :terms]
    end

    def search(message, params)
        limit = params[:number] ? params[:number].to_i : 1
        limit = limit > 5 || limit < 1 ? 1 : limit
        begin
            resp = Net::HTTP.new('www.scroogle.org', 80).request_get("/cgi-bin/nbbw.cgi?Gw=#{CGI::escape(params[:terms])}")
            resp.value
            page = resp.body
            results = []
            page.scan(/<A Href="(.+?)">(.+?)<\/a>/) do |url,title|
                title.gsub!(/<.*?>/, '')
                title = CGI::unescapeHTML(title)
                results.push [title, url]
            end
            output = []
            results.slice(0, limit).each do |title, url|
                output << "#{title} -> #{Helpers.tinyurl(url)} [#{url.scan(/^http:\/\/.+?\//)[0]}]"
            end
            output = output.empty? ? "No results for: \2#{params[:terms]}\2" :  ["Search results for \2#{params[:terms]}:\2"] + output
            reply message.replyto, output
        rescue Object => boom
            @pipeline << Privmsg.new(message.replyto, "Failed to find any results for: #{params[:terms]} Reason: #{boom}")
            Logger.warn("Error: #{boom}\n#{boom.backtrace.join("\n")}")
        end
    end
    
    def search_count(m, params)
        buf = open("http://www.google.com/search?hl=en&q=#{CGI::escape(params[:terms])}", 'UserAgent' => 'mod_spox IRC bot').read
        output = ''
        if(buf =~ /of\s+about.+?([\d,]+)/)
            output = "There are about \2#{$1}\2 results for the term \2#{params[:terms]}\2"
        else
            output = "There are no results found for the term \2#{params[:terms]}\2"
        end
        reply m.replyto, output
    end
end