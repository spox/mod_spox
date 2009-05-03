require 'net/http'

class TracTicket < ModSpox::Plugin
    
    def initialize(pipeline)
        super
        admin = Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'ticket (defect|enhancement|task) (.+?)( # (.+))?', :method => :add_ticket,
                :desc => 'Add new ticket to trac ticket tracker', :params => [:type, :short, :trash, :long])
        add_sig(:sig => 'ticket trac( (\S+))?', :method => :trac_location, :group => admin,
                :desc => 'Show/set trac site', :params => [:trash, :site])
        add_sig(:sig => 'ticket site', :method => :trac_location, :desc => 'Show trac site')
        @site = Config.val(:trac)
    end
    
    def trac_location(message, params)
        if(params[:site])
            site = Config.set(:trac, params[:site])
            @site = params[:site]
            reply message.replyto, "\2Trac Update:\2 Location of trac system has been updated: #{params[:site]}"
        else
            output = "\2Error:\2 Trac site has not yet been set"
            unless(@site.nil?)
                output = "\2Trac location:\2 #{@site}"
            end
            reply message.replyto, output
        end
    end
    
    def add_ticket(message, params)
        if(@site =~ /(http:\/\/)?([^\/:]+)(:\d+)?(.+)$/)
            addr = $2
            port = $3
            path = $4
            port = port.nil? ? 80 : port.gsub(/:/, '').to_i
            con = Net::HTTP.new(addr, port)
            begin
                cookie, fid = get_form_info(con, path)
                long = params[:long] ? params[:long] : params[:short]
                headers = {
                    'Cookie' => cookie,
                    'Referer' => @site,
                    'Content-Type' => 'application/x-www-form-urlencoded'
                }   
                data = "field_reporter=#{URI.escape(message.source.nick)}&field_summary=#{URI.escape(params[:short])}&field_description=#{URI.escape(long)}&field_type=#{URI.escape(params[:type])}&field_status=new&submit=Create%20ticket&field_priority=minor&__FORM_TOKEN=#{URI.escape(fid)}"
                resp, data = con.post(path, data, headers)
                reply message.replyto, 'Ticket was successfully added to tracker'
            rescue Object => boom
                reply message.replyto, "\2Error:\2 Encountered unexpected error while submitting ticket: #{boom}"
            end
        else
            reply message.replyto, "\2Error:\2 Trac location has not been set"
        end
    end
    
    def get_form_info(con, path)
        res, content = con.get(path, {})
        cookie = res['set-cookie']
        if(content =~ /name="__FORM_TOKEN" value="(.+?)"/i)
            return cookie, $1
        else
            raise 'Failed to locate proper identification'
        end
    end
    
end