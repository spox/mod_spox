require 'mod_spox/models/Auth'
require 'mod_spox/models/Signature'

module ModSpox
    module Models

        class Group < Sequel::Model

            many_to_many :auth_masks, :join_table => :auth_masks_groups, :class => 'ModSpox::Models::AuthMask'
            many_to_many :auths, :join_table => :auth_groups, :class => 'ModSpox::Models::Auth'
            one_to_many :signature, :class => 'ModSpox::Models::Signature'

            def name=(group_name)
                group_name.downcase!
                super(group_name)
            end
            
        end
    end
end