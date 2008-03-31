require 'net/http'
require 'cgi'
class Search < ModSpox::Plugin

    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        Models::Signature.find_or_create(:signature => 'search (\d+)? ?(.+)', :plugin => name, :method => 'search', :description => 'Search the internet').params = [:number, :terms]
    end
    
    def search(message, params)
        limit = params[:number] ? params[:number].to_i : 1
        limit = limit > 5 || limit < 1 ? 1 : limit
        begin
            resp = Net::HTTP.new('www.scroogle.org', 80).request_get("/cgi-bin/nbbw.cgi?Gw=#{CGI::escape(params[:terms])}", nil)
            resp.value
            page = resp.body
            results = []
            page.scan(/<A Href="(.+?)">(.+?)<\/a>/) do |url,title|
                title.gsub!(/<.*?>/, '')
                title = CGI::unescapeHTML(title)
                results.push [title, url]
            end
            @pipeline << Privmsg.new(message.replyto, "Search results for \2#{params[:terms]}:\2")
            results.slice(0, limit).each do |title, url|
                @pipeline << Privmsg.new(message.replyto, "#{title} -> #{Helpers.tinyurl(url)} [#{url.scan(/^http:\/\/.+?\//)[0]}]")
            end
        rescue Object => boom
            @pipeline << Privmsg.new(message.replyto, "Failed to find any results for: #{params[:terms]} Reason: #{boom}")
        end
    end
end