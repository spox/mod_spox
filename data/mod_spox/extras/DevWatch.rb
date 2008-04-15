require 'rexml/document'
require 'open-uri'

class DevWatch < ModSpox::Plugin

    include ModSpox::Models

    def initialize(pipeline)
        super(pipeline)
        admin = Group.filter(:name => 'admin').first
        Signature.find_or_create(:signature => 'devwatch (on|off) (\S+)', :plugin => name, :method => 'enable_watch', :group_id => admin.pk,
            :description => 'Turn development watcher on/off in given channel').params = [:status, :channel]
        Signature.find_or_create(:signature => 'devwatch list', :plugin => name, :method => 'watch_list', :group_id => admin.pk,
            :description => 'List all channels on the development watch list')
        Signature.find_or_create(:signature => 'devwatch url ?(\S+)?', :plugin => name, :method => 'set_url', :group_id => admin.pk,
            :description => 'Set URL for development RSS feed').params = [:url]
        Signature.find_or_create(:signature => 'devwatch interval ?(\d+)?', :plugin => name, :method => 'set_interval', :group_id => admin.pk,
            :description => 'Set time interval for notifications').params = [:time]
        if(Setting[:devwatch].nil?)
            Setting.find_or_create(:name => 'devwatch').value = {:channels => [], :interval => 300}
        end
        @pipeline.hook(self, :timer_response, :Internal_TimerResponse)
        @original = nil
        @new = nil
        @timer = nil
        @lock = Mutex.new
        run
    end
    
    def enable_watch(message, params)
        channel = Channel.filter(:name => params[:channel]).first
        if(channel)
            vals = Setting[:devwatch]
            if(params[:status] == 'on')
                vals[:channels] << channel.pk unless vals[:channels].include?(channel.pk)
                reply(message.replyto, "#{channel.name} is now on the development watch list")
            else
                vals[:channels].delete(channel.pk) if vals[:channels].include?(channel.pk)
                reply(message.replyto, "#{channel.name} has been removed from the development watch list")
            end
            Setting.filter(:name => 'devwatch').first.value = vals
            run
        else
            reply(message.replyto, "\2Error:\2 I have no record of #{params[:channel]}.")
        end
    end
    
    def watch_list(message, params)
        if(Setting[:devwatch][:channels].empty?)
            reply(message.replyto, "No channels currently on the development watch list")
        else
            chans = []
            Setting[:devwatch][:channels].each{|id| chans << Channel[id].name}
            reply(message.replyto, "Channels on development watch list: #{chans.join(', ')}")
        end
    end
    
    def set_url(message, params)
        if(params[:url])
            vals = Setting[:devwatch]
            vals[:url] = params[:url]
            reply(message.replyto, "OK")
            Setting.filter(:name => 'devwatch').first.value = vals
            run
        else
            if(Setting[:devwatch].has_key?(:url))
                reply(message.replyto, "\2Devwatch URL:\2 #{Setting[:devwatch][:url]}")
            else
                reply(message.replyto, "\2Error:\2 No URL set for devwatch")
            end
        end
    end
    
    def set_interval(message, params)
        if(params[:time])
            vals = Setting[:devwatch]
            vals[:interval] = params[:time].to_i
            Setting.filter(:name => 'devwatch').first.value = vals
            @timer.reset_period(params[:time].to_i) unless @timer.nil?
            reply(message.replyto, "Devwatch announcement interval reset to: #{Helpers.format_seconds(params[:time].to_i)}")
        else
            reply(message.replyto, "Devwatch announcement interval set to: #{Helpers.format_seconds(Setting[:devwatch][:interval].to_i)}")
        end
    end
    
    def run
        @lock.synchronize do
            check_updates
            if(Setting[:devwatch].has_key?(:url) && Setting[:devwatch][:channels].size > 0)
                if(@timer.nil?)
                    @pipeline << ModSpox::Messages::Internal::TimerAdd.new(self, Setting[:devwatch][:interval].to_i){check_updates}
                    sleep(0.01) while @timer.nil?
                end
            else
                if(@timer)
                    @pipeline << ModSpox::Messages::Internal::TimerRemove.new(@timer)
                    sleep(0.01) until @timer.nil?
                end
            end
        end
    end
    
    def timer_response(message)
        if(message.origin == self && message.action_added?)
            @timer = message.action
        elsif(message.action == @timer && message.action_removed?)
            @timer = nil
        end
    end
    
    def check_updates
        if(Setting[:devwatch].has_key?(:url) && Setting[:devwatch][:channels].size > 0)
            src = open(Setting[:devwatch][:url])
            doc = REXML::Document.new(src.read)
            if @original.nil?
                doc.elements.each('rss/channel/item') do |item|
                    @original = item.elements['title'].text
                    break
                end
                Logger.log("Initialized development watch RSS feed: #{@original}")
            else
                @new = doc
                print_new
            end
        end
    end

    def print_new
        new_items = Array.new
        # run through the list until we hit a duplicate #
        i = 1
        new_orig = nil
        @new.elements.each('rss/channel/item') do |item|
            if item.elements['title'].text == @original
                break
            else
                new_orig = item.elements['title'].text if new_orig.nil?
                new_items << "#{item.elements['title'].text}: #{item.elements['link'].text}"
            end
            i += 1
        end
        @original = new_orig.nil? ? @original : new_orig
        if new_items.size > 0
            new_items.reverse!
            Setting[:devwatch][:channels].each do |id|
                channel = Channel[id]
                new_items.each do |item|
                    reply(channel, item)
                end
            end
        end
    end

end