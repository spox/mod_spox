require 'mod_spox/models/Nick'
require 'mod_spox/models/Group'
module ModSpox
    module Models

        class AuthMask < Sequel::Model

            many_to_many :nicks, :join_table => :auth_masks_nicks, :class => 'Models::Nick'
            many_to_many :groups, :join_table => :auth_masks_groups, :class => 'Models::Group'

            # Checks for any visible users matching any
            # available authentication masks
            def AuthMask.do_auth
                Nick.filter(:visible => true).each do |nick|
                    AuthMask.all.each do |am|
                        am.add_nick(nick) if nick.source =~ /#{am.mask}/
                    end
                end
            end
            
        end
    end
end