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
        Setting[:devwatch] = Hash.new if Setting[:devwatch].nil?
        Setting[:devwatch][:channels] = Array.new unless Setting[:devwatch].has_key?(:channels)
        Setting[:devwatch][:interval] = 300
        @original = nil
        @new = nil
        run
    end
    
    def enable_watch(message, params)
        channel = Channel.filter(params[:channel]).first
        if(channel)
            if(params[:status] == 'on')
                Setting[:devwatch][:channels] << channel.pk unless Setting[:devwatch][:channels].include?(channel.pk)
                reply(message.replyto, "#{channel.name} is now on the development watch list")
            else
                Setting[:devwatch][:channels].delete(channel.pk) if Setting[:devwatch][:channels].include?(channel.pk)
                reply(message.replyto, "#{channel.name} has been removed from the development watch list")
            end
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
            Setting[:devwatch][:url] = params[:url]
            reply(message.replyto, "OK")
        else
            if(Setting[:devwatch].has_key?(:url))
                reply(message.replyto, "\2Devwatch URL:\2 #{Setting[:devwatch][:url]}")
            else
                reply(message.replyto, "\2Error:\2 No URL set for devwatch")
            end
        end
    end
    
    def run
        check_updates
        if(Setting[:devwatch].has_key?(:url) && Setting[:devwatch][:channels].size > 0)
            @pipeline << ModSpox::Messages::Internal::TimerAdd.new(self, Setting[:devwatch][:interval].to_i, nil, true)
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