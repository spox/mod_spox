class Topten < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        ChatStat.create_table unless ChatStat.table_exists?
        Signature.find_or_create(:signature => 'topten', :plugin => name, :method => 'topten',
            :requirement => 'public', :description => 'Show topten users since midnight')
        Signature.find_or_create(:signature => 'topten ([0-9]{4}\/[0-9]{2}\/[0-9]{2})', :plugin => name, :method => 'archive',
            :description => 'Show topten from given date', :requirement => 'public').params = [:date]
        Signature.find_or_create(:signature => 'stats (\S+)', :plugin => name, :method => 'stats', :description => 'Show stats on nick',
            :requirement => 'public').params = [:nick]
        Signature.find_or_create(:signature => 'stats lifetime (\S+)', :plugin => name, :method => 'life_stats',
            :description => 'Show stat totals for given nick', :requirement => 'public').params = [:nick]
        @pipeline.hook(self, :log_stats, :Incoming_Privmsg)
    end
    
    def topten(m, p)
    end
    
    def stats(m, p)
        nick = Nick.locate(p[:nick], false)
        if(nick.is_a?(Nick))
            stat = ChatStat.filter(:nick_id => nick.pk, :channel_id => m.target.pk, :daykey => construct_daykey).first
            if(stat)
                bytes = (stat.bytes > 1023) ? "#{sprintf('%.2f', (stat.bytes / 1024.0))}kb" : "#{stat.bytes}b"
                reply m.replyto, "#{p[:nick]}: #{bytes} logged. #{stat.words} words spoken. #{stat.questions} questions asked."
            else
                reply m.replyto, "\2Error:\2 #{p[:nick]} has no stats recorded for today"
            end
        else
            reply m.replyto, "\2Error:\2 Failed to find record of nick: #{p[:nick]}"
        end
    end
    
    def life_stats(m, p)
    end
    
    def log_stats(m)
        return unless m.is_public?
        key = construct_daykey
        stat = ChatStat.find_or_create(:nick_id => m.source.pk, :channel_id => m.target.pk, :daykey => key)
        words = m.message.scan(/([^ ]+ |[^ ]$)/).size
        bytes = m.message.gsub(/[^a-zA-Z0-9`\~\!@#\$%\^&\*\(\)_\+\[\]\}\{;:'"\/\?\.>,<\\|\-=]/, '').length
        questions = m.message.scan(/.+?(\? |\?$)/).size
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