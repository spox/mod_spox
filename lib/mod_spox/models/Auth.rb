require 'digest/sha1'
require 'mod_spox/models/Group'
require 'mod_spox/models/Nick'
module ModSpox
    module Models
            # Attributes provided by model:
            # password:: Password to autenticate against
            # services:: Authentication by nickserv
            # mask:: Mask to authenticate source against
            # authed:: Nick has authenticated
        class Auth < Sequel::Model

            many_to_many :groups, :join_table => :auth_groups, :class => 'Models::Group'
            many_to_one :nicks, :class => 'Models::Nick'
            
            # Clear relations before destroying
            def before_destroy
                remove_all_groups
            end

            # Is nick identified with services
            def services
                s = values[:services]
                if(s == 0 || s == '0' || !s)
                    return false
                else
                    return true
                end
            end

            # Set services (nickserv) identification
            def services_identified=(val)
                authed = true if val && services
            end

            # pass:: password to compare
            # Check and authenticate against password
            def check_password(pass)
                if(Digest::SHA1.hexdigest(pass) == password)
                    update(:authed => true)
                    return true
                else
                    return false
                end
            end

            def password=(pass)
                pass = pass.nil? ? nil : Digest::SHA1.hexdigest(pass)
                super(pass)
            end

            # source:: source to apply mask to
            # Check and authenticate by mask against source
            def check_mask(source)
                authed = true if source =~ /^#{mask}$/
            end

        end

    end
end