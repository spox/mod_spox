require 'mod_spox/models/Nick'
require 'mod_spox/models/Group'
module ModSpox
    module Models

        class AuthMask < Sequel::Model

            many_to_many :nicks, :join_table => :auth_masks_nicks, :class => 'ModSpox::Models::Nick'
            many_to_many :groups, :join_table => :auth_masks_groups, :class => 'ModSpox::Models::Group'
            
        end
    end
end