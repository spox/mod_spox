require 'net/http'
require 'net/https'

class Headers < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.find_or_create(:name => 'headers')
        add_sig(:sig => 'headers (https?:\/\/\S+)', :method => :fetch_headers, :desc => 'Fetch HTTP headers', :params => [:url])
        add_sig(:sig => 'headers max (\d+)', :method => :set_max, :group => admin, :desc => 'Set maximum number of headers to return', :params => [:max])
        add_sig(:sig => 'headers max', :method => :show_max, :group => admin, :desc => 'Show maximum number of headers to return ')
        @lock = Mutex.new
        @max = Models::Config[:headers_max]
        @max = @max.nil? ? 0 : @max.to_i
    end
    
    def set_max(message, params)
        record = Models::Config.find_or_create(:name => 'headers_max')
        record.value = params[:max].to_i
        record.save
        @max = params[:max].to_i
        reply message.replyto, "Max headers returned set to: #{params[:max].to_i}"
    end
    
    def show_max(message, params)
        reply message.replyto, "Maximum headers returned: #{@max == 0 ? 'no limit' : @max}"
    end

    def fetch_headers(message, params)
        secure = false
        if(params[:url] =~ /^http:/)
            port = 80
        else
            port = 443
            secure = true
        end
        params[:url].gsub!(/^https?:\/\//, '')
        if(params[:url] =~ /:(\d+)/)
            port = $1.to_i
            params[:url].gsub!(/:(\d+)/, '')
        end
        if(params[:url] =~ /(.+?[a-zA-Z]{2,4})(\/.+)$/)
            location = $1
            page = $2
        else
            location = params[:url].gsub(/\/$/, '')
            page = '/'
        end
        begin
            reply message.replyto, "Connecting to: #{location} on port: #{port} retrieving: #{page}"
            con = Net::HTTP.new(location, port)
            con.use_ssl = secure
            con.open_timeout = 5
            con.read_timeout = 5
            response = con.head(page)
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
            reply message.replyto, "Error retrieving headers (#{location}): #{boom}"
            Logger.warn("Headers plugin error: #{boom}")
        end
    end

end