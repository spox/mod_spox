class FloodKicker
    def initialize(pipeline)
        super
        flood = Models::Auth.find_or_create(:name => 'flood')
        @channels = Setting.filter(:name => :floodkicker).first
        @channels = {} if @channels.nil?
        populate_chanhash
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
                reply m.replyto, "Flood kicker lines for this channel currently set at: #{get_chan(m.channel.pk)[:lines]} lines"
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
    end
    
    def listener(m)
    end
    
    private
    
    def save_channels
        s = Models::Setting.find_or_create(:name => 'floodkicker')
        s.value = @channels
        s.save
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