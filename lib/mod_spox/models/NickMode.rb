require 'mod_spox/models/Nick'
require 'mod_spox/models/Channel'
module ModSpox
    module Models

        class NickMode < Sequel::Model
            many_to_one :nick, :class => 'Models::Nick'
            many_to_one :channel, :class => 'Models::Channel'
            
            # m:: mode character
            # add a mode for a nick channel combo
            def set_mode(m)
                update(:mode => "#{values[:mode]}#{m}") if values[:mode].nil? || values[:mode].index(m).nil?
            end
            
            # m:: mode character
            # remove a mode for a nick channel combo
            def unset_mode(m)
                update(:mode => values[:mode].gsub(m, ''))
            end

            def set?(m)
                return mode.nil? ? false : !mode.index(m).nil?
            end
            
            # clear all modes for a nick channel combo
            def clear_modes
                update(:mode => '')
            end
        end
    end
end