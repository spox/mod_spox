require 'rexml/document'
require 'open-uri'
require 'mod_spox/messages/internal/TimerAdd'
require 'mod_spox/messages/internal/TimerRemove'

class DevWatch < ModSpox::Plugin

    include ModSpox::Models

    def initialize(pipeline)
        super(pipeline)
        admin = Group.filter(:name => 'admin').first
        add_sig(:sig => 'devwatch (on|off) (\S+)', :method => :enable_watch, :group => admin, :desc => 'Turn development watcher on/off in given channel', :params => [:status, :channel])
        add_sig(:sig => 'devwatch list', :method => :watch_list, :group => admin, :desc => 'List all channels on the development watch list')
        add_sig(:sig => 'devwatch url ?(\S+)?', :method => :set_url, :group => admin, :desc => 'Set URL for development RSS feed', :params => [:url])
        add_sig(:sig => 'devwatch interval ?(\d+)?', :method => :set_interval, :group => admin, :desc => 'Set time interval for notifications', :params => [:time])
        if(Setting.val(:devwatch).nil?)
            Setting.find_or_create(:name => 'devwatch').value = {:channels => [], :interval => 300}
        end
        @original = nil
        @new = nil
        @timer = {:action => nil, :id => nil}
        start_auto
        check_updates
    end
    
    def enable_watch(message, params)
        channel = Channel.filter(:name => params[:channel]).first
        if(channel)
            vals = Setting.val(:devwatch)
            if(params[:status] == 'on')
                vals[:channels] << channel.pk unless vals[:channels].include?(channel.pk)
                reply(message.replyto, "#{channel.name} is now on the development watch list")
            else
                vals[:channels].delete(channel.pk) if vals[:channels].include?(channel.pk)
                reply(message.replyto, "#{channel.name} has been removed from the development watch list")
            end
            Setting.filter(:name => 'devwatch').first.value = vals
            update_auto
        else
            reply(message.replyto, "\2Error:\2 I have no record of #{params[:channel]}.")
        end
    end
    
    def watch_list(message, params)
        if(Setting.val(:devwatch)[:channels].empty?)
            reply(message.replyto, "No channels currently on the development watch list")
        else
            chans = []
            Setting.val(:devwatch)[:channels].each{|id| chans << Channel[id].name}
            reply(message.replyto, "Channels on development watch list: #{chans.join(', ')}")
        end
    end
    
    def set_url(message, params)
        if(params[:url])
            vals = Setting.val(:devwatch)
            vals[:url] = params[:url]
            reply(message.replyto, "OK")
            Setting.filter(:name => 'devwatch').first.value = vals
            update_auto
        else
            if(Setting.val(:devwatch).has_key?(:url))
                reply(message.replyto, "\2Devwatch URL:\2 #{Setting.val(:devwatch)[:url]}")
            else
                reply(message.replyto, "\2Error:\2 No URL set for devwatch")
            end
        end
    end
    
    def set_interval(message, params)
        if(params[:time])
            vals = Setting.val(:devwatch)
            vals[:interval] = params[:time].to_i
            Setting.filter(:name => 'devwatch').first.value = vals
            if(@timer[:action].nil?)
                update_auto
            else
                @timer[:action].reset_period(params[:time].to_i)
            end
            reply(message.replyto, "Devwatch announcement interval reset to: #{Helpers.format_seconds(params[:time].to_i)}")
        else
            reply(message.replyto, "Devwatch announcement interval set to: #{Helpers.format_seconds(Setting.val(:devwatch)[:interval].to_i)}")
        end
    end
    
    def check_updates
        if(Setting.val(:devwatch).has_key?(:url) && Setting.val(:devwatch)[:channels].size > 0)
            src = open(Setting.val(:devwatch)[:url])
            doc = REXML::Document.new(src.read)
            if @original.nil?
                doc.elements.each('rss/channel/item') do |item|
                    @original = item.elements['title'].text
                    break
                end
                Logger.info("Initialized development watch RSS feed: #{@original}")
            else
                @new = doc
                print_new
            end
        end
    end

    def print_new(max=5)
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
            break if i > max
        end
        @original = new_orig.nil? ? @original : new_orig
        if new_items.size > 0
            new_items.reverse!
            Setting.val(:devwatch)[:channels].each do |id|
                channel = Channel[id]
                new_items.each do |item|
                    reply(channel, item)
                end
            end
        end
    end
    
    def get_timer(m)
        if(m.id == @timer[:id])
            @timer[:action] = m.action_added? ? m.action : nil
        end
    end
    
    def update_auto
        unless(@timer[:action].nil?)
            @pipeline << Messages::Internal::TimerRemove.new(@timer[:action])
        end
        sleep(0.01)
        start_auto
    end
    
    def start_auto
        if(@timer[:action].nil? && Setting.val(:devwatch).has_key?(:url) && Setting.val(:devwatch)[:channels].size > 0)
            m = Messages::Internal::TimerAdd.new(self, Setting.val(:devwatch)[:interval].to_i){ check_updates }
            @timer[:id] = m.id
            @pipeline << m
        end
    end

end