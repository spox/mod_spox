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
            resp = Net::HTTP.new('www.scroogle.org', 80).request_get("/cgi-bin/nbbw.cgi?Gw=#{CGI::escape(params[:terms])}")
            resp.value
            page = resp.body
            results = []
            page.scan(/<A Href="(.+?)">(.+?)<\/a>/) do |url,title|
                title.gsub!(/<.*?>/, '')
                title = CGI::unescapeHTML(title)
                results.push [title, url]
            end
            output = ["Search results for \2#{params[:terms]}:\2"]
            results.slice(0, limit).each do |title, url|
                output << "#{title} -> #{Helpers.tinyurl(url)} [#{url.scan(/^http:\/\/.+?\//)[0]}]"
            end
            reply message.replyto, output
        rescue Object => boom
            @pipeline << Privmsg.new(message.replyto, "Failed to find any results for: #{params[:terms]} Reason: #{boom}")
            Logger.log("Error: #{boom}\n#{boom.backtrace.join("\n")}")
        end
    end
end