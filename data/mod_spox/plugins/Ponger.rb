class Ponger < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        @lag = nil
        @last = nil
        @attempts = 0
        add_sig(:sig => 'lag', :method => :print_lag, :desc => 'Shows bot\'s current lag to server')
        Helpers.load_message(:incoming, :Ping)
        Helpers.load_message(:incoming, :Pong)
        Helpers.load_message(:internal, :PluginsReady)
        Helpers.load_message(:internal, :Reconnect)
        Helpers.load_message(:internal, :TimerAdd)
        @pipeline.hook(self, :ping, ModSpox::Messages::Incoming::Ping)
        @pipeline.hook(self, :get_lag_pong, ModSpox::Messages::Incoming::Pong)
        @lock = Mutex.new
        @pipeline.hook(self, :check_start_ponger, ModSpox::Messages::Internal::PluginsReady)
        @running = false
        send_lag_ping
    end
    
    # message:: ModSpox::Messages::Incoming::Ping
    # Sends responding pongs to server pings
    def ping(message)
        @pipeline << Messages::Outgoing::Pong.new(message.server, message.string)
    end
    
    def send_lag_ping
        if(@attempts > 5)
            @pipeline << Messages::Internal::Reconnect.new
            @lag = nil
            @last = nil
            @attempts = 0
        else
            t = Time.now
            @last = t.to_f.to_s
            @pipeline << Messages::Outgoing::Ping.new("#{@last}")
            @attempts += 1
        end
    end
    
    def get_lag_pong(m)
        @lock.synchronize do
            t = m.string.to_f
            return unless m.string == @last
            @lag = Time.now.to_f - t
            @last = nil
            @attempts = 0
        end
    end
    
    def print_lag(m, params)
        if(@lag.nil?)
            warning m.replyto, 'Lag time currently unavailable'
        else
            information m.replyto, "Current lag time: #{sprintf('%0.4f', @lag)} seconds"
        end
    end
    
    def start_ponger(m)
        @running = true
        send_lag_ping
        @pipeline << Messages::Internal::TimerAdd.new(self, 60){ send_lag_ping }
    end

    def check_start_ponger(m)
        @pipeline << Messages::Internal::TimerAdd.new(self, 30, nil, true){ @lock.synchronize{start_ponger(nil) unless @running} }
    end

end