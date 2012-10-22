module ModSpox
  module Plugins
    class Reloader < ::ModSpox::Plugin

      def add_triggers(m)
        @pipeline << {
          :signature => {
            :regexp => /^reload ?(\S+)?$/, 
            :call => {
              :object => self, 
              :method => :reload_plugin
            }, :matches => [:plugin_name]
          }
        }
        ::ModSpox::Logger.debug "Sent trigger registration information for reloader"
      end

      def reload_plugin(m, args)
        begin
          @plugin_manager.reload_plugin(args[:plugin_name] || :all)
          @irc.privmsg m.target, "#{m.source_nick}: Code reload successful (#{args[:plugin_name] || 'all'})"
        rescue => e
          @irc.privmsg m.target, "Reload failed: #{e}"
          ::ModSpox::Logger.debug "Failed to reload plugin: #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
        end
      end
    end
  end
end
