require 'mod_spox/messages/outgoing/ChannelMode'
class AutoMode < ModSpox::Plugin
    
    include Models
    
    def initialize(pipeline)
        super
        @admin = Group.find_or_create(:name => 'moder')
        @user = Group.find_or_create(:name => 'modee')
        add_sig(:sig => 'addop (\S+)', :method => :addop, :group => @admin, :desc => 'Add a nick to the auto op list', :req => 'public', :params => [:nick])
        add_sig(:sig => 'addvoice (\S+)', :method => :addvoice, :group => @admin, :desc => 'Add a nick to the auto voice list', :req => 'public', :params => [:nick])
        add_sig(:sig => 'op', :method => :op, :group => @user, :desc => 'Instruct bot to give you operator status', :req => 'public')
        add_sig(:sig => 'voice', :method => :voice, :group => @user, :desc => 'Instruct bot to give you voice status', :req => 'public')
        add_sig(:sig => 'automode list (\S+)', :method => :list, :group => @admin, :desc => 'Show list of current auto-modes for channel', :params => [:channel])
        add_sig(:sig => 'delmode (\S+)', :method => :remove, :group => @admin, :desc => 'Remove nick from any auto-modes in channel', :req => 'public', :params => [:nick])
        ModeRecord.create_table unless ModeRecord.table_exists?
        Helpers.load_message(:incoming, :Join)
        @pipeline.hook(self, :check_join, ModSpox::Messages::Incoming::Join)
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
        ModeRecord.filter(:nick_id => m.source.pk, :channel_id => m.target.pk).each do |record|
            @pipeline << Messages::Outgoing::ChannelMode.new(m.target, '+v', m.source.nick) if me.is_op?(m.target) && record.voice
        end
    end
    
    def list(m, p)
        channel = Helpers.find_model(p[:channel], false)
        if(channel.is_a?(Channel))
            records = ModeRecord.filter(:channel_id => channel.pk)
            if(records.count > 0)
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
        if(matches.count > 0)
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
        if(ModeRecord.filter(:nick_id => nick.pk).count < 1)
            nick.remove_group(modee)
        end
    end
    
    class ModeRecord < Sequel::Model
        many_to_one :channel, :class => ModSpox::Models::Channel
        many_to_one :nick, :class => ModSpox::Models::Nick
    end
    
end