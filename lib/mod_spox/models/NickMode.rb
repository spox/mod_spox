require 'mod_spox/models/Nick'
require 'mod_spox/models/Channel'
module ModSpox
    module Models

        class NickMode < Sequel::Model
            many_to_one :nick, :class => 'Models::Nick'
            many_to_one :channel, :class => 'Models::Channel'
            
            # m:: mode character
            # add a mode for a nick channel combo
            def add_mode(m)
                mode = "#{mode}+#{m}"
            end
            
            # m:: mode character
            # remove a mode for a nick channel combo
            def remove_mode(m)
                mode = mode.gsub(m, '')
            end
            
            # clear all modes for a nick channel combo
            def clear_modes
                mode = ''
            end
        end
    end
end