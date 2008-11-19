class Translate < ModSpox::Plugin
    
    include Models
    
    def initialize(pipeline)
        super(pipeline)
        Signature.find_or_create(:signature => 'translate ([a-z]{2}\|[a-z]{2}) (.+)', :plugin => name, :method => 'translate',
            :description => 'Translate text').params = [:lang, :text]
        Signature.find_or_create(:signature => 'autotranslate add ([a-z]{2}) (\S+)', :plugin => name, :method => 'auto_add',
            :description => 'Add a nick to the autotranslate service').params = [:lang, :nick]
        Signature.find_or_create(:signature => 'autotranslate remove (\S+)', :plugin => name, :method => 'auto_remove',
            :description => 'Remove a nick from the autotranslate service').params = [:nick]
        @watchers = {}
        @cache = {}
    end
    
    def auto_add(message, params)
        return unless message.is_public?
        nick = Helpers.find_model(params[:nick], false)
        if(nick && nick.channels.include?(message.target))
            @watchers[message.target.pk] = {} unless @watchers.has_key?(message.target.pk)
            @watchers[message.target.pk][nick.pk] = params[:lang] unless @watchers[message.target.pk].has_key?(nick.pk)
            hook
            reply message.replyto, "#{params[:nick]} is now being tracked for auto translation"
        else
            reply message.replyto, "\2Error:\2 Failed to locate #{params[:nick]}"
        end
    end
    
    def auto_remove(message, params)
        return unless message.is_public?
        nick = Models::Nick.locate(params[:nick], false)
        if(nick)
            if(@watchers.has_key?(message.target.pk))
                @watchers[message.target.pk].delete(nick.pk) if @watchers[message.target.pk].has_key?(nick.pk)
                @watchers.delete(message.target.pk) if @watchers[message.target.pk].empty?
                hook
                reply message.replyto, "#{params[:nick]} is no longer being tracked for auto translation"
            else
                reply message.replyto, "No one is currently being tracked"
            end
        else
            reply message.replyto, "\2Error:\2 Failed to locate #{params[:nick]}"
        end
    end
    
    def translate(message, params)
        reply message.replyto, "\2Translation:\2 #{do_translation(params[:lang], params[:text])}"
    end
    
    def listener(message)
        if(message.is_public? && @watchers.has_key?(message.target.pk))
            if(@watchers[message.target.pk].has_key?(message.source.pk))
                reply message.replyto, "\2Translation (#{message.source.nick}):\2 #{do_translation("#{@watchers[message.target.pk][message.source.pk]}en", message.message)}"
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
                return tr
            else
                raise 'Failed to locate translation'
            end
        else
            raise "Failed to receive result from server"
        end
    end
    
    def hook
        if(@watchers.size == 1)
            @pipeline.hook(self, :listener, :Incoming_Privmsg)
        else
            @pipeline.unhook(self, :listener, :Incoming_Privmsg)
        end
    end
    
end