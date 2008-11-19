require 'net/http'
require 'net/https'

class Headers < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        admin = Models::Group.find_or_create(:name => 'headers')
        Models::Signature.find_or_create(:signature => 'headers (https?:\/\/\S+)', :plugin => name, :method => 'fetch_headers',
            :description => 'Fetch HTTP headers').params = [:url]
        Models::Signature.find_or_create(:signature => 'headers max (\d+)', :plugin => name, :method => 'set_max',
            :group_id => admin.pk, :description => 'Set maximum number of headers to return').params = [:max]
        Models::Signature.find_or_create(:signature => 'headers max', :plugin => name, :method => 'show_max',
            :group_id => admin.pk, :description => 'Show maximum number of headers to return ')
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
        @lock.synchronize do
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
                location = params[:url]
                page = '/'
            end
            begin
                reply message.replyto, "Connecting to: #{location} on port: #{port} retrieving: #{page}"
                con = Net::HTTP.new(location, port)
                con.use_ssl = secure
                response = con.get(page)
                output = ["Response code: #{response.code}"]
                count = 0
                response.each{|key,val|
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
                reply message.replyto, "Error retrieving headers: #{boom}"
                Logger.warn("#{boom}\n#{boom.backtrace.join("\n")}")
            end
        end
    end

end