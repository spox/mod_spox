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
        Setting[:devwatch] = Array.new if Setting[:devwatch].nil?
    end
    
    def enable_watch(message, params)
        channel = Channel.filter(params[:channel]).first
        if(channel)
            if(params[:status] == 'on')
                Setting[:devwatch] << channel.pk unless Setting[:devwatch].include?(channel.pk)
                reply(message.replyto, "#{channel.name} is now on the development watch list")
            else
                Setting[:devwatch].delete(channel.pk) if Setting[:devwatch].include?(channel.pk)
                reply(message.replyto, "#{channel.name} has been removed from the development watch list")
            end
        else
            reply(message.replyto, "\2Error:\2 I have no record of #{params[:channel]}.")
        end
    end
    
    def watch_list(message, params)
        if(Setting[:devwatch].nil?)
            reply(message.replyto, "No channels currently on the development watch list")
        else
            chans = []
            Setting[:devwatch].each{|id| chans << Channel[id].name}
            reply(message.replyto, "Channels on development watch list: #{chans.join(', ')}")
        end
    end

end