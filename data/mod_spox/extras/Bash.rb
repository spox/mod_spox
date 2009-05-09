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
            if m.length > 1
                m = m.delete_if{|x| x[0].length > 200 }
                raise 'Only overly long quotes found' unless m.length > 0
            end
            i = rand(m.length)                  # NOTE: this works fine for individuals, since rand(1) is always 0
            n = m[i][0].gsub(/<[^<]+>/, '')     # select a random quote
            o = Helpers.convert_entities(n)     # unescape html entities
            p = o.gsub("\r\n", " ").strip       # replace newlines with spaces and trim
            q = p.gsub(/(<([^>]+)>(?:[^<]+))<\2>/){ $1 }    # replace duplicated name tags; condense lines
            r = q.gsub(/\s{2,}/, ' ')           # condense spaces
            return r
        rescue Object => boom
            Logger.error(boom)
            raise boom
        end
    end
end

