# ex: set ts=4 et:
require "net/http"

# downforeveryoneorjustme.com website-upness-checker plugin
# by pizza

class Bash < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig    => 'down ((?:(?:[a-z0-9][a-z0-9-]*)\.)+[a-z]+)',
                :method => :down,
                :desc   => 'Check website status',
                :params => [:domain])
        @site = 'http://downforeveryoneorjustme.com/'
    end
    
    def down(m, params)
        begin
            # check for valid domain
            dom = params[:domain].downcase
            url = @site + domain
            reply m.replyto, get_text(domain, url)
        rescue Object => boom
            error m.replyto, "Failed to fetch. #{boom}"
        end
    end
    
    private
    
    def get_text(domain, url)
        begin
            t = "#{domain} appears "
            data = Net::HTTP.get_response(URI.parse(url)).body
            if /is up/.match(data)
                t = t + "up"
            else
                t = t + "down"
            return t
        rescue Object => boom
            Logger.error(boom)
            raise boom
        end
    end
end

