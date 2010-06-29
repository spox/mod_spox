require 'net/http'

module Splib
    # url:: URL to shorten
    # Gets a tinyurl for given URL
    def self.tiny_url(url)
        connection = Net::HTTP.new('tinyurl.com', 80)
        resp, data = connection.get("/api-create.php?url=#{url}")
        if(resp.code !~ /^200$/)
            raise "Failed to make the URL small."
        end
        return data.strip
    end
    # url:: URL to shorten
    # Gets a tr.im for given URL
    def self.trim_url(url)
        connection = Net::HTTP.new('api.tr.im', 80)
        resp, data = connection.get("/v1/trim_simple?url=#{url}")
        if(resp.code !~ /^200$/)
            raise "Failed to make the URL small."
        end
        return data.strip
    end
    # url:: URL to shorten
    # Gets a is.gd for given URL
    def self.isgd_url(url)
        connection = Net::HTTP.new('is.gd', 80)
        resp, data = connection.get("/api.php?longurl=#{url}")
        if(resp.code !~ /^200$/)
            raise "Failed to make the URL small."
        end
        return data.strip
    end
    # url:: URL to shorten
    # Get shortest for given url
    def self.shortest_url(url)
        results = []
        [:tiny_url, :isgd_url, :trim_url].each do |service|
            begin
                results << self.send(service, url)
            rescue
                #ignore#
            end
        end
        raise 'Failed to make URL small' if results.empty?
        results.sort{|a,b| a.length <=> b.length}[0]
    end
end