module ModSpox
  module Plugins
    class Quiter < ::ModSpox::Plugin

      def add_triggers(m)
        @pipeline << {
          :signature => {
            :regexp => /^quit(.*)$/, 
            :call => {
              :object => self, 
              :method => :quit
            }, :matches => [:message]
          }
        }
        ::ModSpox::Logger.debug 'Sent trigger registration information for quiter'
      end

      def quit(m, args)
        @irc.quit args[:message]
      end
    end
  end
end
