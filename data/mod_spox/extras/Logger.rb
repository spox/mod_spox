class ChatLogger < ModSpox::Plugin

    # This plugin creates a log of conversations the bot sees. It
    # is important to note that the order in which messages are
    # added to the database may not be in order. Due to the
    # async behavior of the pipeline, this plugin may (and most
    # likely will) receive messages out of order. This will be most
    # notable with triggers received and responses from the bot

    include Models

    def initialize(pipeline)
        super
        PublicLog.create_table unless PublicLog.table_exists?
        PrivateLog.create_table unless PrivateLog.table_exists?
        @pipeline.hook(self, :log_privmsg, :Incoming_Privmsg)
        @pipeline.hook(self, :log_join, :Incoming_Join)
        @pipeline.hook(self, :log_part, :Incoming_Part)
        @pipeline.hook(self, :log_quit, :Incoming_Quit)
        @pipeline.hook(self, :log_kick, :Incoming_Kick)
        @pipeline.hook(self, :log_mode, :Incoming_Mode)
        @pipeline.hook(self, :log_privmsg, :Incoming_Notice)
        @pipeline.hook(self, :log_outpriv, :Outgoing_Privmsg)
        @pipeline.hook(self, :log_outpriv, :Outgoing_Notice)
        Signature.find_or_create(:signature => 'seen (\S+)', :plugin => name, :method => 'seen', :description => 'Report last sighting of nick').params = [:nick]
        Signature.find_or_create(:signature => 'lastspoke (\S+)', :plugin => name, :method => 'spoke', :description => 'Report last time nick spoke').params = [:nick]
    end
    
    def log_outpriv(message)
        type = message.is_a?(Messages::Outgoing::Privmsg) ? 'privmsg' : 'notice'
        type = 'action' if message.is_action?
        target = message.target.is_a?(Sequel::Model) ? message.target : Helpers.find_model(message.target)
        if(target.is_a?(Models::Channel))
            PublicLog.new(:message => message.message, :type => type, :sender => me.pk,
                :channel => target.pk, :received => Time.now).save
        else
            PrivateLog.new(:message => message.message, :type => type, :sender => me.pk,
                :receiver => target.pk, :received => Time.now).save
        end        
    end
    
    def log_privmsg(message)
        type = message.is_a?(Messages::Incoming::Privmsg) ? 'privmsg' : 'notice'
        type = 'action' if message.is_action?
        if(message.is_public?)
            PublicLog.new(:message => message.message, :type => type, :sender => message.source.pk,
                :channel => message.target.pk, :received => Time.now).save
        else
            PrivateLog.new(:message => message.message, :type => type, :sender => message.source.pk,
                :receiver => message.target.pk, :received => Time.now).save
        end
    end
    
    def log_join(message)
        PublicLog.new(:type => 'join', :sender => message.nick.pk, :channel => message.channel.pk, :received => Time.now).save
    end
    
    def log_part(message)
        PublicLog.new(:message => message.reason, :type => 'part', :sender => message.nick.pk,
            :channel => message.channel.pk, :received => Time.now).save
    end
    
    def log_quit(message)
        PublicLog.new(:message => message.message, :type => 'quit', :sender => message.nick.pk, :received => Time.now).save
    end
    
    def log_kick(message)
        PublicLog.new(:message => "#{message.kickee.pk}|#{message.reason}", :type => 'kick', :sender => message.kicker.pk,
            :channel => message.channel.pk, :received => Time.now).save
    end
    
    def log_mode(message)
        if(message.for_channel?)
            PublicLog.new(:message => message.mode, :type => 'mode', :sender => message.source.pk,
                :channel => message.channel.pk, :received => Time.now).save
        else
            PrivateLog.new(:message => message.mode, :type => 'mode', :sender => message.source.pk,
                :receiver => message.target.pk, :received => Time.now).save
        end
    end
    
    def seen(m, p)
        nick = Helpers.find_model(p[:nick], false)
        if(nick.is_a?(Models::Nick))
            record = PublicLog.filter(:sender => nick.pk).order(:received).last
            record_p = PrivateLog.filter(:sender => nick.pk).order(:received).last
            record = record_p if !record || (record_p && record && record_p.received > record.received)
            if(record)
                if(record.is_a?(PublicLog))
                    case record.values[:type]
                        when 'join'
                            message = "joining #{Channel[record.channel].name}"
                        when 'part'
                            message = "parting #{Channel[record.channel].name} with the message: #{record.message}"
                        when 'privmsg'
                            message = "in #{Channel[record.channel].name} saying: #{record.message}"
                        when 'action'
                            message = "in #{Channel[record.channel].name} saying: * #{p[:nick]} #{record.message}"
                        when 'notice'
                            message = "in #{Channel[record.channel].name} saying: #{record.message}"
                        when 'kick'
                            if(record.message =~ /^([0-9]+)\|/)
                                kickee = Nick[$1.to_i]
                                reason = $2
                                message = "kicking #{kickee.nick} from #{Channel[record.channel].name} (#{record.message})"
                            end
                        end
                else
                    message = "saying to me: #{record.message}"
                end
                reply m.replyto, "I last saw #{p[:nick]} on #{record.received} #{message}"
            else
                reply m.replyto, "\2Error:\2 Failed to find record of #{p[:nick]}"
            end
        else
            reply m.replyto, "\2Error:\2 Failed to find record of #{p[:nick]}"
        end
    end
    
    def spoke(m, p)
        nick = Helpers.find_model(p[:nick], false)
        if(nick.is_a?(Models::Nick))
            record = PublicLog.filter(:sender => nick.pk).filter("type in ('privmsg', 'action')").order(:received).last
            record_p = PrivateLog.filter(:sender => nick.pk).order(:received).last
            record = record_p if !record || (record_p && record && record_p.received > record.received)
            if(record)
                if(record.is_a?(PublicLog))
                    reply m.replyto, "I last saw #{p[:nick]} on #{record.received} saying: #{record.values[:type] == 'action' ? "* #{p[:nick]} #{record.message}" : record.message}"
                else
                    reply m.replyto, "I last saw #{p[:nick]} on #{record.received} saying to me: #{record.message}"
                end
            else
                reply m.replyto, "\2Error:\2 Failed to find record of #{p[:nick]}"
            end
        else
            reply m.replyto, "\2Error:\2 Failed to find record of #{p[:nick]}"
        end        
    end
    
    class PrivateLog < Sequel::Model
        set_schema do
            primary_key :id
            text :message, :null => false
            text :type, :null => false, :default => 'privmsg'
            boolean :action, :null => false, :default => false
            timestamp :received, :null => false
            foreign_key :sender, :table => :nicks
            foreign_key :receiver, :table => :nicks
            index :message, :type => :full_text
        end
    end
    
    class PublicLog < Sequel::Model
        set_schema do
            primary_key :id
            text :message
            text :type, :null => false, :default => 'privmsg'
            boolean :action, :null => false, :default => false
            timestamp :received, :null => false
            foreign_key :sender, :table => :nicks
            foreign_key :channel, :table => :channels
            index :message, :type => :full_text
        end
    end

end