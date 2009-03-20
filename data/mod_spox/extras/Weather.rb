class Weather < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        add_sig(:sig => 'weather (\d+)', :method => :weather, :desc => 'Show weather for given zipcode', :params => [:zipcode])
    end
    
    def weather(message, params)
        connection = Net::HTTP.new('www.weather.com', 80)
        response = connection.request_get("/weather/local/#{params[:zipcode]}?lswe=96094&lwsa=WeatherLocalUndeclared&from=whatwhere", nil)
        begin
            response.value
            page = response.body.gsub(/[\r\n]/, ' ')
            if page =~ /R for (.+?) \(.+?>([0-9]+)&.+?Like<BR> ([0-9]+)&.+?UV In.+?TextA">(.+?)\s*<.+?Wind.+?TextA">(.+?)\s*<.+?idity.+?TextA">(.+?)\s*<.+?ssure.+?TextA">(.+?)\s*<.+?oint.+?TextA">(.+?)\s*<.+?bility.+?TextA">(.+?)\s*</
                location = $1
                curtemp = $2
                feeltemp = $3
                uv = $4
                wind = $5
                humid = $6
                pressure = $7
                dewpoint = $8
                visibility = $9
                future = Array.new
                i = 0
                page.scan(/.+?ialLink11"><B>(.+?)</).each{|match| future.push(match[0])}
                page.scan(/font.+?lueFont10">([^<].+?)<\/nobr>/).each{|match|
                    future[i] << "|#{match[0].gsub(/<.+?>/, '').gsub(/&.+?;/, '').gsub(/\s+/, ' ')}"
                    i += 1
                }
                i = 0
                for item in future do
                    if item =~ /^([^\|]+)\|(.+)$/
                        future[i] = "\2#{$1}:\2 #{$2}"
                    else
                        future.delete_at(i)
                    end
                    i += 1
                end
                output = ["Weather for: \2#{location}\2"]
                output << "Current Temp: #{curtemp} - Feels like: #{feeltemp}"
                output << "[UV Index: #{uv.gsub(/&.+?;/, '')}][Wind: #{wind.gsub(/&.+?;/, '')}][Humidity: #{humid.gsub(/&.+?;/, '')}][Pressure: #{pressure.gsub(/&.+?;/, '')}][Dew Point: #{dewpoint.gsub(/&.+?;/, '')}][Visibility: #{visibility.gsub(/&.+?;/, '')}]"
                output << future.values_at(0..2).join(' ')
                reply message.replyto, output
            else
                reply message.replyto, "Failed to retrieve weather data."
            end
        rescue Object => boom
            reply message.replyto, "Error: Received invalid response from server"
        end
    end

end