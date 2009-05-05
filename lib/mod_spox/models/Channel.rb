require 'mod_spox/models/Nick'
require 'mod_spox/models/ChannelMode'
require 'mod_spox/models/NickMode'

module ModSpox
    module Models

        # Attributes provided by model:
        # name:: Channel name
        # password:: Channel password
        # autojoin:: Set bot to autojoin this channel
        # topic:: Channel topic
        # quiet:: Silence the bot in this channel
        # parked:: Bot is currently in this channel
        class Channel < Sequel::Model

            many_to_many :nicks, :join_table => :nick_channels, :class => 'Models::Nick'
            many_to_one :mode, :one_to_one => true, :class => 'Models::ChannelMode'
            one_to_many :nick_modes, :class => 'Models::NickMode'

            # chan_name:: string
            # set channel name after downcase
            def name=(chan_name)
                chan_name.downcase!
                super(chan_name)
            end

            def Channel.find_or_create(args)
                args[:name].downcase! if args[:name]
                super(args)
            end

            def Channel.filter(args)
                args[:name].downcase! if args[:name]
                super(args)
            end

            def Channel.locate(string, create = true)
                string.downcase!
                chan = Channel.filter(:name => string).first
                if(!chan && create)
                    chan = Channel.find_or_create(:name => string)
                end
                return chan
            end

            def set_mode(m)
                mode.set(m)
            end

            def unset_mode(m)
                mode.unset(m)
            end

            # Removes all nicks from this channel
            def clear_nicks
                remove_all_nicks
            end

            def add_nick(n)
                if(nicks.map{|nick| true if n.nick == nick.nick}.empty?)
                    super(n)
                end
            end

            def remove_nick(n)
                unless(nicks.map{|nick| true if n.nick == nick.nick}.empty?)
                    super(n)
                end
            end

        end

    end
end