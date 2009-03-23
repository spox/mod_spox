class Ponger < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        @lag = nil
        @last = nil
        @attempts = 0
        add_sig(:sig => 'lag', :method => :print_lag, :desc => 'Shows bot\'s current lag to server')
        @pipeline.hook(self, :ping, :Incoming_Ping)
        @pipeline.hook(self, :get_lag_pong, :Incoming_Pong)
        @lock = Mutex.new
        @pipeline.hook(self, :start_ponger, :Incoming_Motd)
        @pipeline.hook(self, :check_start_ponger, :Internal_SignaturesUpdate)
    end
    
    # message:: ModSpox::Messages::Incoming::Ping
    # Sends responding pongs to server pings
    def ping(message)
        @pipeline << Messages::Outgoing::Pong.new(message.server, message.string)
    end
    
    def send_lag_ping
        if(@attempts > 2)
            @pipeline << Messages::Internal::Disconnected.new
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
        send_lag_ping
        @pipeline << Messages::Internal::TimerAdd.new(self, 60){ send_lag_ping }
    end

    def check_start_ponger(m)
        @pipeline << Messages::Internal::TimerAdd.new(self, 30, nil, true){ start_ponger(nil) if @lag.nil? }
    end

end