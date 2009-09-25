require 'net/http'
require 'net/https'
require 'uri'

class Headers < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.find_or_create(:name => 'headers')
        add_sig(:sig => 'headers ((https?:\/\/)?\S+)', :method => :fetch_headers, :desc => 'Fetch HTTP headers', :params => [:url])
        add_sig(:sig => 'headers max (\d+)', :method => :set_max, :group => admin, :desc => 'Set maximum number of headers to return', :params => [:max])
        add_sig(:sig => 'headers max', :method => :show_max, :group => admin, :desc => 'Show maximum number of headers to return ')
        @lock = Mutex.new
        @max = Models::Config.val(:headers_max)
        @max = @max.nil? ? 0 : @max.to_i
    end
    
    def set_max(message, params)
        record = Models::Config.set(:headers_max, params[:max].to_i)
        @max = params[:max].to_i
        reply message.replyto, "Max headers returned set to: #{params[:max].to_i}"
    end
    
    def show_max(message, params)
        reply message.replyto, "Maximum headers returned: #{@max == 0 ? 'no limit' : @max}"
    end

    def fetch_headers(message, params)
        params[:url] = "http://#{params[:url]}" unless params[:url].slice(0..3).downcase == 'http'
        uri = URI.parse(params[:url])
        begin
            check_private(uri)
            path = uri.path.nil? || uri.path.empty? ? '/' : uri.path
            path += "?#{uri.query}" unless uri.query.nil?
            reply message.replyto, "Connecting to: #{uri.host} on port: #{uri.port} retrieving: #{path}"
            con = Net::HTTP.new(uri.host, uri.port)
            #con.secure = uri.scheme == 'https'
            con.open_timeout = 5
            con.read_timeout = 5
            response = con.head(path)
            output = ["Response code: #{response.code}"]
            count = 0
            response.each_capitalized{|key,val|
                output << "#{key.slice(0..50)}: #{val.slice(0..200)}"
                count += 1
                break if @max != 0 && count >= @max
            }
            if(count >= @max && @max != 0)
                output << 'Maximum header limit reached.'
            else
                output << 'Header listing complete'
            end
            reply message.replyto, output
        rescue Object => boom
            reply message.replyto, "Error retrieving headers (#{uri.host}): #{boom}"
            Logger.warn("Headers plugin error: #{boom}")
        end
    end

    def check_private
        raise 'This host is within a private network address' if uri.host =~ /^(10\.|172\.(#{(16..31).to_a.join('|')})|192\.168)/
    end

end