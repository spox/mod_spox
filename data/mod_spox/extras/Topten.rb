class Topten < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        ChatStat.create_table unless ChatStat.table_exists?
        add_sig(:sig => 'topten', :method => :topten, :req => 'public', :desc => 'Show topten users since midnight')
        add_sig(:sig => 'topten ([0-9]{4}\/[0-9]{2}\/[0-9]{2})', :method => :archive, :desc => 'Show topten from given date', :req => 'public', :params => [:date])
        add_sig(:sig => 'stats ?(\S+)?', :method => :stats, :desc => 'Show stats on nick', :req => 'public', :params => [:nick])
        add_sig(:sig => 'stats lifetime (\S+)?', :method => :life_stats, :desc => 'Show stat totals for given nick', :req => 'public', :params => [:nick])
        @pipeline.hook(self, :log_stats, :Incoming_Privmsg)
    end
    
    def topten(m, p)
        stats = ChatStat.filter(:channel_id => m.target.pk, :daykey => construct_daykey).reverse_order(:bytes).limit(10)
        if(stats.size > 0)
            users = []
            stats.each do |stat|
                bytes = (stat.bytes > 1023) ? "#{sprintf('%.2f', (stat.bytes / 1024.0))}kb" : "#{stat.bytes}b"
                users << "#{Nick[stat.nick_id].nick}: #{bytes}"
            end
            reply m.replyto, "\2Topten:\2 #{users.join(', ')}"
        else
            reply m.replyto, "\2Error:\2 No stats found for this channel."
        end
    end
    
    def archive(m, p)
        stats = ChatStat.filter(:channel_id => m.target.pk, :daykey => p[:date]).reverse_order(:bytes).limit(10)
        if(stats.size > 0)
            users = []
            stats.each do |stat|
                bytes = (stat.bytes > 1023) ? "#{sprintf('%.2f', (stat.bytes / 1024.0))}kb" : "#{stat.bytes}b"
                users << "#{Nick[stat.nick_id].nick}: #{bytes}"
            end
            reply m.replyto, "\2Topten:\2 #{users.join(', ')}"
        else
            reply m.replyto, "\2Error:\2 No stats found for date given."
        end
    end
    
    def stats(m, p)
        nick = p[:nick] ? Nick.locate(p[:nick], false) : m.source
        if(nick.is_a?(Nick))
            stat = ChatStat.filter(:nick_id => nick.pk, :channel_id => m.target.pk, :daykey => construct_daykey).first
            if(stat)
                bytes = (stat.bytes > 1023) ? "#{sprintf('%.2f', (stat.bytes / 1024.0))}kb" : "#{stat.bytes}b"
                reply m.replyto, "#{nick.nick}: #{bytes} logged. #{stat.words} words spoken. #{stat.questions} questions asked."
            else
                reply m.replyto, "\2Error:\2 #{nick.nick} has no stats recorded for today"
            end
        else
            reply m.replyto, "\2Error:\2 Failed to find record of nick: #{p[:nick]}"
        end
    end
    
    def life_stats(m, p)
        nick = p[:nick] ? Nick.locate(p[:nick], false) : m.source
        if(nick)
            result = ChatStat.group(:nick_id).select(:SUM[:bytes].as(:tbytes), :SUM[:words].as(:twords), :SUM[:questions].as(:tquestions)).filter(:nick_id => nick.pk).first
            bytes = (result[:tbytes] > 1023) ? "#{sprintf('%.2f', (result[:tbytes] / 1024.0))}kb" : "#{result[:tbytes]}b"
            reply m.replyto, "#{nick.nick} (total): #{bytes} logged, #{result[:twords]} words spoken and #{result[:tquestions]} questions asked"
        else
            reply m.replyto, "\2Error:\2 Failed to find #{p[:nick]}"
        end
    end
    
    def log_stats(m)
        return unless m.is_public?
        key = construct_daykey
        stat = ChatStat.find_or_create(:nick_id => m.source.pk, :channel_id => m.target.pk, :daykey => key)
        words = m.message.scan(/([^ ]+ |[^ ]$)/).size
        bytes = m.message.gsub(/[^a-zA-Z0-9`\~\!@#\$%\^&\*\(\)_\+\[\]\}\{;:'"\/\?\.>,<\\|\-=]/, '').length
        questions = m.message.scan(/.+?(!?\?!? |!?\?!?$)/).size
        stat.words += words
        stat.bytes += bytes
        stat.questions += questions
        stat.save
    end
    
    private
    
    def construct_daykey
        t = Time.now
        return "#{t.year}/#{sprintf('%02d', t.month)}/#{sprintf('%02d', t.day)}"
    end
    
    class ChatStat < Sequel::Model
        set_schema do
            primary_key :id
            integer :words, :null => false, :default => 0
            integer :bytes, :null => false, :default => 0
            integer :questions, :null => false, :default => 0
            varchar :daykey, :null => false
            foreign_key :channel_id, :table => :channels
            foreign_key :nick_id, :table => :nicks
        end
    end

end