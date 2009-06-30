class Locator < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'locate (\S+)', :method => :locate, :desc => 'Locate the given nick', :params => [:nick])
    end

    def locate(m, params)
        nick = Models::Nick.filter(:nick => params[:nick]).first
        if(nick)
            if(!nick.address.nil? && !nick.address.empty?)
                con = Net::HTTP.new('www.ip-adress.com', 80)
                res = con.request_get("/ip_tracer/#{nick.address}", nil)
                begin
                    info = []
                    res.value
                    page = res.body
                    page = page.split("\n")
                    page.size.times do |line|
                        unless(page[line].index('IP address country:').nil?)
                            info << "\2Country:\2 #{page[line+2].gsub(/<.+?>/, '').strip}"
                        end
                        unless(page[line].index('IP address state:').nil?)
                            info << "\2State:\2 #{page[line+2].gsub(/<.+?>/, '').strip}"
                        end
                        unless(page[line].index('IP address city:').nil?)
                            info << "\2City:\2 #{page[line+2].gsub(/<.+?>/, '').strip}"
                        end
                        unless(page[line].index('ISP of this IP').nil?)
                            info << "\2ISP:\2 #{page[line+2].gsub(/<.+?>/, '').strip}"
                        end
                    end
                    reply m.replyto, "\2Locator:\2 #{params[:nick]} - #{info.join(', ')}"
                rescue Object => boom
                    Logger.error("Locator plugin generated an exception: #{boom}")
                end
            else
                error m.replyto, "Current address unavailable for nick: #{params[:nick]}"
            end
        else
            error m.replyto, "Failed to find record of nick: #{params[:nick]}"
        end
    end
end