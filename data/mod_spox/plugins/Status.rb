require 'mod_spox/messages/internal/StatusRequest'

class Status < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'status', :method => :status, :desc => 'Show current status')
        add_sig(:sig => 'version', :method => :version, :desc => 'Show version information')
        add_sig(:sig => 'VERSION', :method => :version, :desc => 'Show version information')
        @pipeline.hook(self, :get_status, :Internal_StatusResponse)
        @resp = []
    end
    
    def status(m, pa)
        @resp << m.replyto
        @pipeline << Messages::Internal::StatusRequest.new(self)
    end
    
    def version(message, params)
        reply message.replyto, "mod_spox IRC bot - Version: \2#{ModSpox.botversion}\2 (#{ModSpox.botcodename}) [http://modspox.rubyforge.org]"
    end
    
    def get_status(m)
        @resp.uniq!
        @resp.each do |c|
            reply c, "\2Status:\2 \2Uptime:\2 #{m.status[:uptime]} \2Plugins:\2 #{m.status[:plugins]} loaded \2Socket Connected:\2 #{m.status[:socket_connect].strftime("%Y/%m/%d-%H:%M:%S")} \2Lines sent:\2 #{m.status[:sent]} \2Lines Received:\2 #{m.status[:received]}"            
            @resp.delete(c)
        end
    end

end