module ModSpox
  module Plugins
    # Responds to PING messages from the server
    class Ponger < ModSpox::Plugin

      # Seconds of lag to server. Returns nil if unknown
      attr_reader :lag

      def setup
        @pipeline.hook(MessageFactory::Message, self, :ping){|m|m.type == :ping}
        @pipeline.hook(MessageFactory::Message, self, :pong){|m|m.type == :pong}
        @lag = nil
        @lock = Splib::Monitor.new
        @pinger = @timer.add(:period => 60){ @irc.ping(Time.now.to_f.to_s) }
      end

      def destroy
        super
        @timer.remove(@pinger)
      end

      # m:: MessageFactory::Message
      # Send returning pong
      def ping(m)
        @irc.pong(m.server, m.message)
      end

      # m:: MessageFactory::Message
      # Process returned pong
      def pong(m)
        now = Time.now.to_f
        before = m.message.to_f
        @lock.synchronize{ @lag = now - before }
        Logger.debug "Current lag time: #{@lag} seconds"
      end
    end
  end
end