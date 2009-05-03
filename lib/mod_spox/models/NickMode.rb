require 'mod_spox/models/Nick'
require 'mod_spox/models/Channel'
module ModSpox
    module Models

        class NickMode < Sequel::Model
            many_to_one :nick, :class => 'Models::Nick'
            many_to_one :channel, :class => 'Models::Channel'
        end
    end
end