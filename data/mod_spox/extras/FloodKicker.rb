class FloodKicker
    def initialize(pipeline)
        super
        flood = Models::Auth.find_or_create(:name => 'flood')
        @watched = []
        @channels = Setting.filter(:name => :floodkicker).first
        @channels = [] if @channels.nil?
        @channels.each do |c|
            @watched << c[:channel]
        end
        @data = {}
        @pipeline.hook(self, :listener, :Incoming_Privmsg)
        add_sig(:sig => 'floodkick enable(\s \S+)?', :method => :add_channel, :group => flood,
                :desc => 'Add channel to flood kicker', :params => [:channel])
        add_sig(:sig => 'floodkick disable(\s \S+)?', :method => :remove_channel, :group => flood,
                :desc => 'Remove channel from flood kicker', :params => [:channel])
        add_sig(:sig => 'floodkick lines(\s \d+)?', :method => :max_lines, :group => flood,
                :desc => 'Maximum number of lines in allowed time', :params => [:lines])
        add_sig(:sig => 'floodkick seconds(\s \d+)?', :method => :max_seconds, :group => flood,
                :desc => 'Maximum number of seconds for allowed lines', :params => [:seconds])
        add_sig(:sig => 'floodkick status(\s \S+)?', :method => :status, :desc => 'Show parameters for given channel',
                :params => [:channel])
    end
#    @channels -> {:channel => chan.pk, :lines => \d+, :seconds => \d+}
    
    def add_channel(m, params)
        chan = params[:channel] ? Models::Channel.locate(params[:channel].strip) : m.channel
        unless(watched_channels_ids.include?(chan.pk))
            @channels << {:channel => chan.pk, :lines => 5, :seconds => 1}
            save_channels
            reply m.replyto, "Flood kicker is now enabled for: #{chan.name}"
        else
            reply m.replyto, "\2Error:\2 Flood kicker is already enabled for: #{chan.name}"
        end
    end
    
    def remove_channel(m, params)
        chan = params[:channel] ? Models::Channel.locate(params[:channel].strip) : m.channel
        if(watched_channels_ids.include?(chan.pk))
            @channels.delete(get_chan(chan.pk))
            save_channels
            reply m.replyto, "Flood kicker is now disabled for: #{chan.name}"
        else
            reply m.replyto, "Flood kicker is not enabled for: #{chan.name}"
        end
    end
    
    def max_lines(m, params)
        lines = params[:lines] ? params[:lines].to_i : nil
        chan = get_chan(m.channel.pk)
        unless(chan.nil?)
            if(lines.nil? || lines == 0)
                reply m.replyto, "Flood kicker lines for this channel currently set at: #{chan[:lines]} lines"
            else
                chan[:lines] = lines
                save_channels
                reply m.replyto, "Flood kicker lines updated to: #{lines} lines"
            end
        else
            reply m.replyto, "\2Error:\2 Flood kicker is not enabled in this channel"
        end
    end
    
    def max_seconds(m, params)
        seconds = params[:seconds] ? params[:seconds].to_i : nil
        chan = get_chan(m.channel.pk)
        unless(chan.nil?)
            if(seconds.nil? || seconds == 0)
                reply m.replyto, "Flood kicker seconds for this channel currently set at: #{chan[:seconds]} seconds"
            else
                chan[:seconds] = seconds
                save_channels
                reply m.replyto, "Flood kicker seconds updated to: #{seconds} seconds"
            end
        else
            reply m.replyto, "\2Error:\2 Flood kicker is not enabled in this channel"
        end
    end
    
    def listener(m)
        if(@watched.include?(m.channel.pk))
            log_message(m)
            if(kick_nick?(m.nick, m.channel))
                chan = get_chan(m.channel.pk)
                @pipeline << Messages::Outgoing::Kick.new(m.nick, m.channel, "Flooding. (exceeded #{chan[:lines]} lines in #{chan[:seconds]} seconds)")
            end
        end
    end
    
    private
    
    def log_message(m)
        @data[m.channel.pk] = {} unless @data.has_key?(m.channel.pk)
        @data[m.channel.pk][m.nick.pk] = [] unless @data[m.channel.pk].has_key?(m.nick.pk)
        @data[m.channel.pk][m.nick.pk] << {:time => Time.now, :message => m.message}
        @data[m.channel.pk][m.nick.pk].shift until @data[m.channel.pk][m.nick.pk].size <= get_chan(m.channel.pk)[:lines]
    end
    
    def kick_nick?(nick, channel)
        chan = get_chan(channel.pk)
        if(@data[channel.pk].has_key?(nick.pk) && @data[channel.pk][nick.pk].size == chan[:lines])
            return @data[channel.pk][nick.pk][@data[channel.pk][nick.pk].size - 1][:time].to_i - @data[channel.pk][nick.pk][0].to_i >= chan[:seconds].to_i
        else
            return false
        end
    end
    
    def save_channels
        s = Models::Setting.find_or_create(:name => 'floodkicker')
        s.value = @channels
        s.save
        @watched.clear
        @channels.each{|c| @watched << c.pk}
    end
    
    def watched_channels
        @channels.collect{|c| Models::Channel[c[:channel]]}
    end
    
    def watched_channels_ids
        @channels.collect{|c| c[:channel]}
    end
    
    def get_chan(pk)
        @channels.each do |c|
            return c if c[:channel] == pk
        end
    end
end