require 'digest/sha1'
module ModSpox
    module Models
    
            # Attributes provided by model:
            # password:: Password to autenticate against
            # services:: Authentication by nickserv
            # mask:: Mask to authenticate source against
            # authed:: Nick has authenticated
        class Auth < Sequel::Model(:auths)
            
            # Nick associated with this Auth
            def nick
                Nick[nick_id]
            end
            
            def services
                s = values[:services]
                if(s == 0 || s == '0' || !s)
                    return false
                else
                    return true
                end
            end
            
            # Groups this auth is a member of
            def groups
                # we grab IDs, then the object. Otherwise we get sync problems
                group_id = []
                AuthGroup.filter(:auth_id => pk).each do |ag|
                    group_id << ag.group_id
                end
                group = []
                group_id.each{|id| group << Group[id]}
                return group
            end
            
            # Add group to this auth's list
            def group=(group)
                AuthGroup.find_or_create(:auth_id => pk, :group_id => group.pk)
            end
            
            # Remove given group from auth
            def remove_group(group)
                AuthGroup.filter(:auth_id => pk, :group_id => group.pk).each{|g|g.destroy}
            end
            
            # Set services (nickserv) identification
            def services_identified=(val)
                set :authed => true if val && services
            end
            
            # pass:: password to compare
            # Check and authenticate against password
            def check_password(pass)
                if(Digest::SHA1.hexdigest(pass) == password)
                    set :authed => true
                    return true
                else
                    return false
                end
            end
            
            def password=(pass)
                set :password => Digest::SHA1.hexdigest(pass)
            end
            
            # source:: source to apply mask to
            # Check and authenticate by mask against source
            def check_mask(source)
                if(source =~ /^#{mask}$/)
                    set :authed => true
                end
            end
            
        end
        
    end
end