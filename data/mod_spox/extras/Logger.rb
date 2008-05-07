class Logger < ModSpox::Plugin

    def initialize(pipeline)
        super
        @pipeline.hook(self, :log_privmsg, :Incoming_Privmsg)
        @pipeline.hook(self, :log_join, :Incoming_Join)
        @pipeline.hook(self, :log_part, :Incoming_Part)
        @pipeline.hook(self, :log_quit, :Incoming_Quit)
        @pipeline.hook(self, :log_kick, :Incoming_Kick)
        @pipeline.hook(self, :log_mode, :Incoming_Mode)
        @pipeline.hook(self, :log_privmsg, :Incoming_Notice)
    end
    
    def log_privmsg(message)
        type = message.is_a?(Messages::Incoming::Privmsg) ? 'privmsg' : 'notice'
        if(message.public?)
            PublicLog.new(:message => message.message, :type => type, :sender => message.source.pk,
                :channel => message.target.pk, :received => Time.now).save
        else
            PrivateLog.new(:message => message.message, :type => type, :sender => message.source.pk,
                :receiver => message.target.pk, :received => Time.now).save
        end
    end
    
    def log_part(message)
        PublicLog.new(:message => message.reason, :type => 'part', :sender => message.source.pk,
            :channel => message.target.pk, :received => Time.now).save
    end
    
    def log_quit(message)
        PublicLog.new(:message => message.message, :type => 'quit', :sender => message.source.pk,
            :channel => message.target.pk, :received => Time.now).save
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
    
    class PrivateLog < Sequel::Model
        set_schema do
            primary_key :id
            text :message, :null => false
            text :type, :null => false, :default => 'privmsg'
            boolean :action, :null => false, :default => false
            timestamp :received, :null => false
            foreign_key :sender, :table => :nicks
            foreign_key :receiver, :table => :nicks
        end
    end
    
    class PublicLog < Sequel::Model
        set_schema do
            primary_key :id
            text :message, :null => false
            text :type, :null => false, :default => 'privmsg'
            boolean :action, :null => false, :default => false
            timestamp :received, :null => false
            foreign_key :sender, :table => :nicks
            foreign_key :channel, :table => :channels
        end
    end

end