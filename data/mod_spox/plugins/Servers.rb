class Servers < ModSpox::Plugin
    def initialize(pipeline)
        super
        admin = Models::Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'servers list', :method => :list, :group => admin, :desc => 'Show server list')
        add_sig(:sig => 'servers add (\S+) (\d+)( \d+)?', :method => :add, :group => admin, :desc => 'Add server to list', :params => [:server, :port, :prio])
        add_sig(:sig => 'servers del (\d+)', :method => :remove, :group => admin, :desc => 'Remove server from list', :params => [:id])
        add_sig(:sig => 'servers prio (\d+) (\+|\-|\d+)', :method => :prio, :group => admin, :desc => 'Prioritize server', :params => [:id, :move])
    end

    def list(m, params)
        output = ["\2Server list:\2"]
        Models::Server.reverse_order(:priority).each do |s|
            output << "\2[#{s.id}]\2 #{s.host}:#{s.port} \2Priority:\2 #{s.priority}"
        end
        reply m.replyto, output
    end

    def add(m, params)
        begin
            s = Models::Server.new(:host => params[:server], :port => params[:port].to_i)
            s.priority = params[:prio].to_i if params[:prio]
            s.save
            information m.replyto, "New server has been added: #{params[:server]}:#{params[:port]}"
        rescue Object => boom
            error m.replyto, "Failed to add new server. Reason: #{boom}"
        end
    end

    def remove(m, params)
        begin
            raise "List must contain one server" unless Models::Server.count > 1
            Models::Server[params[:id].to_i].destroy
            information m.replyto, 'Server has been removed'
        rescue Object => boom
            error m.replyto, "Failed to remove server. Reason: #{boom}"
        end
    end

    def prio(m, params)
        begin
            s = Models::Server[params[:id].to_i]
            if(params[:move] == '+')
                s.priority += 1
            elsif(params[:move] == '-')
                s.priority -= 1 if s.priority > 0
            else
                s.priority = params[:move].to_i
            end
            s.save_changes
            information m.replyto, 'Server priority has been updated.'
        rescue Object => boom
            error m.replyto, "Failed to update priority. Reason: #{boom}"
        end
    end
    
end