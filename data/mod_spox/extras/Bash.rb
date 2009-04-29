# ex: set ts=4 et:
require "net/http"
require "cgi"

# bash.org quote plugin
# by pizza

class Bash < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'bash( (top|latest|#\d+))?', :method => :random, :desc => 'Bash quote fetcher', :params => [:wspace, :cmd])
        @site = 'http://bash.org/'
    end
    
    def random(m, params)
        begin
            u = @site + '?top'
            if 'latest' == params[:cmd]
              u = @site + '?latest'
            elsif /^#(\d+)$/.match(params[:cmd])
              u = @site + '?' + $1
            end
            reply m.replyto, get_text(u)
        rescue Object => boom
            error m.replyto, "Failed to fetch. #{boom}"
        end
    end
    
    private
    
    def get_text(url)
        begin
            data = Net::HTTP.get_response(URI.parse(url)).body
            # parse individual entries, they have a "qt" section within "quote"
            m = data.scan(/<p class="qt">(.*?)<\/p>/m)
            raise 'No quotes found' unless m.length > 0
            i = rand(m.length)              # select random index
                                            # NOTE: this works fine for individuals, since rand(1) is always 0
            q = m[i][0].gsub(/<[^<]+>/, '') # select a random quote
            q.gsub!("\r\n", " ")            # replace newlines with spaces
            s = Helpers.convert_entities(q) # unescape html entities
            s.strip!
            s.gsub!(/(<([^>]+)>(?:[^<]+))<\2>/){ $1 }  # replace duplicated name tags; condense lines
            return s.gsub(/\s{2,}/, ' ')
        rescue Object => boom
            Logger.error(boom)
            raise boom
        end
    end
end

