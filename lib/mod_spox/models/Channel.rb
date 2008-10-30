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

            set_cache Database.cache, :ttl => 3600 unless Database.cache.nil?

            def name=(chan_name)
                update_values :name => chan_name.downcase
            end

            def Channel.locate(string, create = true)
                string.downcase!
                chan = Channel.filter(:name => string).first
                if(!chan && create)
                    chan = Channel.find_or_create(:name => string)
                end
                return chan
            end

            # Modes for this channel
            def channel_modes
                ChannelMode.filter(:channel_id => pk)
            end

            # Nicks residing within this channel
            def nicks
                all_nicks = []
                NickChannel.filter(:channel_id => pk).each do |nc|
                    all_nicks << nc.nick
                end
                return all_nicks
            end

            # Adds a nick to this channel
            def nick_add(nick)
                NickChannel.find_or_create(:channel_id => pk, :nick_id => nick.pk)
            end

            # Removes a nick from this channel
            def nick_remove(nick)
                NickChannel.filter(:channel_id => pk, :nick_id => nick.pk).first.destroy
            end

            # Removes all nicks from this channel
            def clear_nicks
                NickChannel.filter(:channel_id => pk, :nick_id => nick.pk).each{|o| o.destroy}
            end

            # Purges all channel information
            def self.clean
                Channel.set(:topic => nil, :parked => false)
                ChannelMode.destroy_all
            end

        end

    end
end