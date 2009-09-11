class Seen < ModSpox::Plugin
    def initialize(pipe)
        super
        SeenLog.create_table unless SeenLog.table_exists?
        [:Privmsg, :Join, :Part, :Quit, :Kick, :Notice].each{|t| Helpers.load_message(:incoming, t)}
        [:Privmsg, :Notice].each{|t|Helpers.load_message(:outgoing, t)}
        @pipeline.hook(self, :log_privmsg, ModSpox::Messages::Incoming::Privmsg)
        @pipeline.hook(self, :log_join, ModSpox::Messages::Incoming::Join)
        @pipeline.hook(self, :log_part, ModSpox::Messages::Incoming::Part)
        @pipeline.hook(self, :log_quit, ModSpox::Messages::Incoming::Quit)
        @pipeline.hook(self, :log_kick, ModSpox::Messages::Incoming::Kick)
        @pipeline.hook(self, :log_privmsg, ModSpox::Messages::Incoming::Notice)
        @pipeline.hook(self, :log_outpriv, ModSpox::Messages::Outgoing::Privmsg)
        @pipeline.hook(self, :log_outpriv, ModSpox::Messages::Outgoing::Notice)
        add_sig(:sig => 'seen (\S+)', :method => :seen, :desc => 'Report last sighting of nick', :params => [:nick])
    end

    def seen(m, params)
        nick = Models::Nick.filter(:nick => params[:nick]).first
        log = SeenLog.filter(:nick_id => nick.pk).first if nick
        if(nick && log)
            message = "I last saw #{params[:nick]} on #{log.received} "
            case log.type
                when 'join'
                    message << "joining #{log.channel.name}"
                when 'part'
                    message << "parting #{log.channel.name} "
                    message << "reason: #{log.message}" unless log.message.nil? || log.message.empty?
                when 'privmsg'
                    message << "in #{log.channel.name} " unless log.channel.nil?
                    message << "saying #{log.message}" unless log.action
                    message << "doing: #{log.message}" if log.action
                when 'notice'
                    message << "in #{log.channel.name} " unless log.channel.nil?
                    message << "sending notice: #{log.message}"
                when 'kicking'
                    mes = log.message.dup
                    k = mes.slice!(0..mes.index('|')-1)
                    mes.slice!(0)
                    k = Models::Nick[k.to_i]
                    message << "kicking #{k.nick} from #{log.channel.name} (Reason: #{mes})"
                when 'kicked'
                    mes = log.message.dup
                    k = mes.slice!(0..mes.index('|')-1)
                    mes.slice!(0)
                    k = Models::Nick[k.to_i]
                    message << "kicked from #{log.channel.name} by #{k.nick} (Reason: #{mes})"
            end
            information m.replyto, message
        else
            error m.replyto, "Failed to find record of given nick: #{params[:nick]}"
        end
    end

    def log_outpriv(message)
        type = message.instance_of?(Messages::Outgoing::Privmsg) ? 'privmsg' : 'notice'
        target = message.target.is_a?(Sequel::Model) ? message.target : Helpers.find_model(message.target)
        target = nil unless target.is_a?(Models::Channel)
        log = get_log(me.pk)
        log.action = message.is_action?
        log.message = message.message
        log.type = type
        log.channel = target unless target.nil?
        log.received = Time.now
        log.save
    end
    
    def log_privmsg(message)
        return unless message.source.is_a?(Models::Nick)
        type = message.instance_of?(Messages::Incoming::Privmsg) ? 'privmsg' : 'notice'
        target = message.target.is_a?(Sequel::Model) ? message.target : Helpers.find_model(message.target)
        target = nil unless target.is_a?(Models::Channel)
        log = get_log(message.source.pk)
        log.action = message.is_action?
        log.message = message.message
        log.type = type
        log.channel = target unless target.nil?
        log.received = message.time
        log.save
    end
    
    def log_join(message)
        log = get_log(message.nick.pk)
        log.action = false
        log.message = nil
        log.type = 'join'
        log.channel = message.channel
        log.received = message.time
        log.save
    end
    
    def log_part(message)
        log = get_log(message.nick.pk)
        log.action = false
        log.type = 'part'
        log.message = message.reason
        log.channel = message.channel
        log.received = message.time
        log.save
    end
    
    def log_quit(message)
        log = get_log(message.nick.pk)
        log.action = false
        log.type = 'quit'
        log.message = message.message
        log.channel = nil
        log.received = message.time
        log.save
    end
    
    def log_kick(message)
        # log kicker
        log = get_log(message.kicker.pk)
        log.action = false
        log.type = 'kicking'
        log.channel = message.channel
        log.received = message.time
        log.message = "#{message.kickee.pk}|#{message.reason}"
        log.save
        # log kickee
        log = get_log(message.kickee.pk)
        log.action = false
        log.type = 'kicked'
        log.channel = message.channel
        log.received = message.time
        log.message = "#{message.kicker.pk}|#{message.reason}"
        log.save
    end

    private
    
    def get_log(pk)
        log = SeenLog.filter(:nick_id => pk).first
        log = SeenLog.new(:nick_id => pk) unless log
        return log
    end

    class SeenLog < Sequel::Model
        many_to_one :nick, :class => ModSpox::Models::Nick
        many_to_one :channel, :class => ModSpox::Models::Channel
    end
end