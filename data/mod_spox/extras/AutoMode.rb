class AutoMode < ModSpox::Plugin
    
    include Models
    
    def initialize(pipeline)
        super
        @admin = Group.find_or_create(:name => 'moder')
        @user = Group.find_or_create(:name => 'modee')
        Signature.find_or_create(:signature => 'addop (\S+)', :plugin => name, :method => 'addop', :group_id => @admin.pk,
            :description => 'Add a nick to the auto op list', :requirement => 'public').params = [:nick]
        Signature.find_or_create(:signature => 'addvoice (\S+)', :plugin => name, :method => 'addvoice', :group_id => @admin.pk,
            :description => 'Add a nick to the auto voice list', :requirement => 'public').params = [:nick]
        Signature.find_or_create(:signature => 'op', :plugin => name, :method => 'op', :group_id => @user.pk,
            :description => 'Instruct bot to give you operator status', :requirement => 'public')
        Signature.find_or_create(:signature => 'voice', :plugin => name, :method => 'voice', :group_id => @user.pk,
            :description => 'Instruct bot to give you voice status', :requirement => 'public')
        Signature.find_or_create(:signature => 'automode list (\S+)', :plugin => name, :method => 'list', :group_id => @admin.pk,
            :description => 'Show list of current auto-modes for channel').params = [:channel]
        Signature.find_or_create(:signature => 'delmode (\S+)', :plugin => name, :method => 'remove', :group_id => @admin.pk,
            :description => 'Remove nick from any auto-modes in channel', :requirement => 'public').params = [:nick]
        ModeRecord.create_table unless ModeRecord.table_exists?
        @pipeline.hook(self, :check_join, :Incoming_Join)
    end
    
    def addop(m, p)
        nick = Helpers.find_model(p[:nick], false)
        if(nick.is_a?(Nick))
            ModeRecord.find_or_create(:nick_id => nick.pk, :channel_id => m.target.pk, :voice => false)
            add_modee(nick)
            reply m.replyto, "#{nick.nick} has been added to the auto-op list"
        else
            reply m.replyto, "\2Error:\2 Failed to find record of: #{p[:nick]}"
        end
    end
    
    def addvoice(m, p)
        nick = Helpers.find_model(p[:nick], false)
        if(nick.is_a?(Nick))
            ModeRecord.find_or_create(:nick_id => nick.pk, :channel_id => m.target.pk, :voice => true)
            add_modee(nick)
            reply m.replyto, "#{nick.nick} has been added to the auto-voice list"
        else
            reply m.replyto, "\2Error:\2 Failed to find record of: #{p[:nick]}"
        end
    end
    
    def op(m, p)
        record = ModeRecord.filter(:nick_id => m.source.pk, :channel_id => m.target.pk).first
        if(record && !record.voice)
            @pipeline << Messages::Outgoing::ChannelMode.new(m.target, '+o', m.source.nick) if me.is_op?(m.target)
        else
            reply m.replyto, "\2Error:\2 You are not listed on the auto-op list"
        end
    end
    
    def voice(m, p)
        record = ModeRecord.filter(:nick_id => m.source.pk, :channel_id => m.target.pk).first
        if(record && record.voice)
            @pipeline << Messages::Outgoing::ChannelMode.new(m.target, '+v', m.source.nick) if me.is_op?(m.target)
        else
            reply m.replyto, "\2Error:\2 You are not listed on the auto-voice list"
        end
    end
    
    def list(m, p)
        channel = Helpers.find_model(p[:channel], false)
        if(channel.is_a?(Channel))
            records = ModeRecord.filter(:channel_id => channel.pk)
            if(records.size > 0)
                reply m.replyto, "\2Auto-Mode Listing:\2"
                sleep(0.01)
                records.each do |record|
                    reply m.replyto, "#{record.nick.nick} \2->\2 #{record.voice == false ? "op" : "voice"}"
                end
            else
                reply m.replyto, "\2Warning:\2 No users found in auto-mode list"
            end
        else
            reply m.replyto, "\2Error:\2 Failed to find channel: #{p[:channel]}"
        end
    end
    
    def remove(m, p)
        nick = Helpers.find_model(p[:nick], false)
        if(nick.is_a?(Nick))
            ModeRecord.filter(:channel_id => m.target.pk, :nick_id => nick.pk).destroy
            remove_modee(nick)
            reply m.replyto, "All auto-modes for user: #{p[:nick]} have been removed"
        else
            reply m.replyto, "\2Error:\2 Failed to find nick: #{p[:nick]}"
        end
    end
    
    def check_join(m)
        return unless me.is_op?(m.channel)
        matches = ModeRecord.filter(:nick_id => m.nick.pk, :channel_id => m.channel.pk)
        if(matches.size > 0)
            matches.each do |record|
                mode = record.voice ? '+v' : '+o'
                @pipeline << Messages::Outgoing::ChannelMode.new(m.channel, mode, m.nick.nick)
            end
        end
    end
    
    def add_modee(nick)
        modee = Group.find_or_create(:name => 'modee')
        nick.group = modee
    end
    
    def remove_modee(nick)
        modee = Group.find_or_create(:name => 'modee')
        if(ModeRecord.filter(:nick_id => nick.pk).size < 1)
            nick.remove_group(modee)
        end
    end
    
    class ModeRecord < Sequel::Model
        set_schema do
            primary_key :id
            boolean :voice, :null => false, :default => true
            foreign_key :nick_id, :table => :nicks, :null => false
            foreign_key :channel_id, :table => :channels, :null => false
            index [:nick_id, :channel_id, :voice], :unique => true
        end
        
        def channel
            ModSpox::Models::Channel[channel_id]
        end
        
        def nick
            ModSpox::Models::Nick[nick_id]
        end
    end
    
end