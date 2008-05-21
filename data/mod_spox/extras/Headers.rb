require 'net/http'
require 'net/https'

class Headers < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        Models::Signature.find_or_create(:signature => 'headers (https?:\/\/\S+)', :plugin => name, :method => 'fetch_headers',
            :description => 'Fetch HTTP headers').params = [:url]
        @lock = Mutex.new
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
                response = con.get(page, nil)
                output = ["Response code: #{response.code}"]
                response.each{|key,val|
                    output << "#{key}: #{val}"
                }
                output << "Header listing complete"
                reply message.replyto, output
            rescue Object => boom
                reply message.replyto, "Error retrieving headers: #{boom}"
            end
        end
    end

end