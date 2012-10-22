module ModSpox
  module Plugins
    class Joiner < ::ModSpox::Plugin
      def setup
        @pipeline.hook(::MessageFactory::Message, self, :send_who){|m|m.type == :join}
      end

      def add_triggers(m)
        @pipeline << {
          :signature => {
            :regexp => /^join (\S+)$/, 
            :call => {
              :object => self, 
              :method => :join
            }, :matches => [:channel]
          }
        }
        ::ModSpox::Logger.debug "Sent trigger registration information for joiner"
      end

      def join(m, args)
        @irc.join args[:channel]
      end

      def send_who(m, args)
        @irc.who m.target if m.nick == current_nick
      end
    end
  end
end
