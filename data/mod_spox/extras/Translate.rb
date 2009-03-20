class Translate < ModSpox::Plugin
    
    include Models
    
    def initialize(pipeline)
        super(pipeline)
        begin
            require 'htmlentities'
        rescue Object => boom
            Logger.warn('Error: This plugin requires the HTMLEntities gem. Please install and reload plugin.')
            raise Exceptions::BotException.new("Missing required HTMLEntities library")
        end
        add_sig(:sig => 'translate ([a-z]{2}\|[a-z]{2}) (.+)', :method => :translate, :desc => 'Translate text', :params => [:lang, :text])
        add_sig(:sig => 'autotranslate add ([a-z]{2}) (\S+)', :method => :auto_add, :desc => 'Add a nick to the autotranslate service', :params => [:lang, :nick])
        add_sig(:sig => 'autotranslate remove (\S+)', :method => :auto_remove, :desc => 'Remove a nick from the autotranslate service', :params => [:nick])
        add_sig(:sig => 'translate languages', :method => :langs, :desc => 'Show available languages')
        @pipeline.hook(self, :listener, :Incoming_Privmsg)
        @watchers = {}
        @cache = {}
        @coder = HTMLEntities.new
        @allowed = {'zh'=>'Chinese-simplified','zt'=>'Chinese-traditional','en'=>'English','nl'=>'Dutch',
                    'fr'=>'French','de'=>'German','el'=>'Greek','it'=>'Italian','ja'=>'Japanese',
                    'ko'=>'Korean','pt'=>'Portuguese','ru'=>'Russian','es'=>'Spanish'}
        @allowed_trans = ['zh_en','zh_zt', 'zt_en', 'zt_zh', 'en_zh', 'en_zt', 'en_nl', 'en_fr', 'en_de',
                          'en_el', 'en_it', 'en_ja', 'en_ko', 'en_pt', 'en_ru', 'en_es', 'nl_en', 'nl_fr',
                          'fr_nl', 'fr_en', 'fr_de', 'fr_el', 'fr_it', 'fr_pt', 'fr_es', 'de_en', 'de_fr',
                          'el_en', 'el_fr', 'it_en', 'it_fr', 'ja_en', 'ko_en', 'pt_en', 'pt_fr', 'ru_en',
                          'es_en', 'es_fr']
    end
    
    def langs(m, params)
        output = ['Available languages for translate:']
        s = []
        @allowed.each_pair{|k,v| s << "#{v} (\2#{k}\2)"}
        output << s.join(', ')
        reply m.replyto, output
    end
    
    def auto_add(message, params)
        return unless message.is_public?
        if(@allowed_trans.include?("en_#{params[:lang]}") && @allowed_trans.include?("#{params[:lang]}_en"))
            nick = Helpers.find_model(params[:nick], false)
            if(nick && nick.channels.include?(message.target))
                @watchers[message.target.pk] = {} unless @watchers.has_key?(message.target.pk)
                @watchers[message.target.pk][nick.pk] = params[:lang] unless @watchers[message.target.pk].has_key?(nick.pk)
                reply message.replyto, "#{params[:nick]} is now being tracked for auto translation"
            else
                reply message.replyto, "\2Error:\2 Failed to locate #{params[:nick]}"
            end
        else
            reply message.replyt, "\2Error:\2 Unsupported bi-directional translation"
        end
    end
    
    def auto_remove(message, params)
        return unless message.is_public?
        nick = Models::Nick.locate(params[:nick], false)
        if(nick)
            if(@watchers.has_key?(message.target.pk))
                @watchers[message.target.pk].delete(nick.pk) if @watchers[message.target.pk].has_key?(nick.pk)
                @watchers.delete(message.target.pk) if @watchers[message.target.pk].empty?
                reply message.replyto, "#{params[:nick]} is no longer being tracked for auto translation"
            else
                reply message.replyto, "No one is currently being tracked"
            end
        else
            reply message.replyto, "\2Error:\2 Failed to locate #{params[:nick]}"
        end
    end
    
    def translate(message, params)
        begin
            reply message.replyto, "\2Translation:\2 #{do_translation(params[:lang], params[:text])}"
        rescue Object => boom
            reply message.replyto, "\2Error:\2 #{boom}"
        end
    end
    
    def listener(message)
        if(message.is_public? && @watchers.has_key?(message.target.pk))
            if(@watchers[message.target.pk].has_key?(message.source.pk))
                trans_message = do_translation("#{@watchers[message.target.pk][message.source.pk]}en", message.message)
                reply message.replyto, "\2Translation (#{message.source.nick}):\2 #{trans_message}" unless trans_message == message.message
            elsif(message.message =~ /^(\S+)[:,]/)
                Logger.info("Translate matched a followed nick: #{$1}")
                nick = Helpers.find_model($1, false)
                return unless nick
                if(@watchers[message.target.pk].has_key?(nick.pk))
                    reply message.replyto, "\2(#{do_translation("en|#{@watchers[message.target.pk][nick.pk]}", 'translation')})\2 #{do_translation("en|#{@watchers[message.target.pk][nick.pk]}", message.message)}"
                end
            end
        end
    end
    
    private
    
    def do_translation(langs, text)
        raise 'Unsupported language combination for translation' unless @allowed_trans.include?(langs.gsub(/\|/, '_'))
        if(@cache.has_key?(langs) && @cache[langs].has_key?(text))
            return @cache[langs][text]
        end
        content = Net::HTTP.post_form(URI.parse('http://babelfish.yahoo.com/translate_txt'), {
            'ei' => 'UTF-8',
            'doit' => 'done',
            'fr' => 'bf-home',
            'intl' => '1',
            'tt' => 'urltext',
            'trtext' => text,
            'lp' => langs.gsub(/\|/, '_'),
            'btnTrTxt' => 'Translate'
        }).body
        if(content)
            if(content =~ /<div id="result">(.+?)<input/im)
                tr = $1
                tr.gsub!(/<.+?>/, '')
                tr.gsub!(/[\r\n]/, ' ')
                tr.gsub!(/\s+/, ' ')
                if(text.length < 15)
                    @cache[langs] = {} unless @cache.has_key?(langs)
                    @cache[langs][text] = tr
                end
                return @coder.decode(tr).strip
            else
                raise 'Failed to locate translation'
            end
        else
            raise "Failed to receive result from server"
        end
    end
    
end