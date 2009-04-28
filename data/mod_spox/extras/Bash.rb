# ex: set ts=4 et:
require "net/http"
require "cgi"

# bash.org quote plugin
# by pizza

class Bash < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'bash( (top|latest))?', :method => :random, :desc => 'Bash quote fetcher', :params => [:wspace, :cmd])
        @site = 'http://bash.org/'
    end
    
    def random(m, params)
        begin
            u = @site + '?top'
            if 'latest' == params[:cmd]
              u = @site + 'latest'
            elsif /^#(\d+)$/.match(params[:cmd])
              u = @site + '?' + $1
            end
            reply m.replyto, get_text(u)
        rescue Object => boom
            error m.replyto, 'Failed to fetch.' + boom.to_s
        end
    end
    
    private
    
    def get_text(url)
        begin
            data = Net::HTTP.get_response(URI.parse(url)).body
            if /\d$/.match(url)
                # parse individual entries, they have a "qt" section within "quote"
                m = data.scan(/(?:<p class="qt">.*)(&lt;(?:.*?\r\n)+.*?)<\/p>/s)
            else
                # all the quote lists use a "quote" section
                m = data.scan(/(?:<p class="quote">.*)(&lt;(?:.*?\r\n)+.*?)<\/p>/s)
            end
            i = rand(m.length)              # select random index
                                            # NOTE: this works fine for individuals, since rand(1) is always 0
            q = m[i][0]                     # select a random quote
            r = q.gsub("<br />\r\n", " ")   # replace newlines with spaces
            s = CGI::unescapeHTML(r)        # unescape html entities
            t = s.gsub("&nbsp;", " ")       # FIXME: for some reason this doesn't get escaped?(!)
            u = t
            [ # replace weird chars left in at least one of the quotes
                [ "\x85", "..." ],
                [ "\x92", "'"   ],
                [ "\x93", "\""  ],
                [ "\x94", "\""  ],
            ].each{|x| u.gsub!(x[0], x[1]) }
            v = u.gsub(/[\x80-\xFF]+/, "")  # nuke weird straggler chars
            w = u.strip
            x = w.gsub(/(<([^>]+)>(?:[^<]+))<\2>/){ $1 }  # replace duplicated name tags; condense lines
            puts x
        rescue Object => boom
            puts boom
        end
    end
end

