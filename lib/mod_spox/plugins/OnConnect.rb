module ModSpox
  module Plugins
    # Sends initial credentials on connection
    class OnConnect < ModSpox::Plugin
      def setup
        @pipeline.hook(Messages::Connected, self, :on_connect)
        @nick = nil
        @username = nil
        @real_name = nil
      end

      # message:: Messages::Connected
      # Sends credentials to server
      def on_connect(message)
        get_nick_info
        @irc.nick(@nick)
        @irc.user(@username, 8, @real_name)
      end

      private

      def get_nick_info
        info = PStore.new("#{ModSpox.config_dir}/bot.pstore")
        info.transaction do
          @nick = info[:nick]
          @username = info[:username]
          @real_name = info[:realname]
        end
      end
    end
  end
end
