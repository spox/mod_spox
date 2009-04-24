class Permissions < ModSpox::Plugin

    def initialize(pipe)
        super
        admin = Models::Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'perm (\S+)', :group => admin, :method => :show_perm, :desc => 'Display permissions for plugin', :params => [:plugin])
        add_sig(:sig => 'perm (\d+) (\S+)', :group => admin, :method => :set_perm, :desc => 'Sets permission for signature with given ID', :params => [:id, :group])
        add_sig(:sig => 'group add (\S+)', :group => admin, :method => :add_group, :desc => 'Add a new authentication group', :params => [:group])
        add_sig(:sig => 'invalid', :group => admin, :method => :invalid, :desc => 'foobar')
    end
    
    def show_perm(m, params)
        output = ["Permissions for signatures owned by \2#{params[:plugin]}\2"]
        Models::Signature.filter(:plugin => params[:plugin]).each do |s|
            g = s.group
            output << "[#{s.pk}] \2#{g.is_a?(Models::Group) ? g.name : 'unset'}\2 - #{s.signature} - #{s.description}"
        end
        if(output.size > 1)
            reply m.replyto, output
        else
            error m.replyto, "Failed to locate signatures for given plugin: #{params[:plugin]}"
        end
    end
    
    def set_perm(m, params)
        s = Models::Signature[params[:id].to_i]
        if(s)
            if(params[:group] == 'none')
                g = true
            else
                g = Models::Group.filter(:name => params[:group]).first
            end
            if(g)
                s.group_id = g.is_a?(Models::Group) ? g.pk : nil
                s.save
                information m.replyto, "Signature with ID #{s.pk} has been updated to group: #{g.is_a?(Models::Group) ? g.name : 'unset'}"
            else
                error m.replyto, "Group name is invalid. If it is a new group, add it first. (#{params[:group]})"
            end
        else
            error m.replyto, "Failed to find signature with ID: #{params[:id]}"
        end
    end
    
    def add_group(m, params)
        begin
            raise 'Invalid group name: none' if params[:group] == 'none'
            Models::Group.find_or_create(:name => params[:group])
            information m.replyto, "New group \2#{params[:group]}\2 is now available"
        rescue Object => boom
            error m.replyto, "Unknown error when adding new group: #{params[:group]}"
        end
    end
    
    def invalid(m, params)
        Models::Signature.dataset.update(:enabled => false)
        information m.replyto, 'ok'
    end

end