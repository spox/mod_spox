module ModSpox
  module Plugins
    class Nicker < ::ModSpox::Plugin

      def add_triggers(m)
        @pipeline << {
          :signature => {
            :regexp => /^nick (\S+)$/, 
            :call => {
              :object => self, 
              :method => :change_nick
            }, :matches => [:new_nick]
          }
        }
        ::ModSpox::Logger.debug 'Sent trigger registration information for nicker'
      end

      def change_nick(m, args)
        @irc.nick args[:new_nick]
      end

    end
  end
end
