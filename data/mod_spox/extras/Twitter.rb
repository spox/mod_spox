require 'open-uri'
require 'uri'

class Twitter < ModSpox::Plugin

    def initialize(pipeline)
        super
        begin
            require 'htmlentities'
        rescue Object => boom
            Logger.warn('Error: This plugin requires the HTMLEntities gem. Please install and reload plugin.')
            raise Exceptions::BotException.new("Missing required HTMLEntities library")
        end
        begin
            require 'twitter'
            require 'json'
            c = %q{
                class ModClient < Object::Twitter::Client
                    def login
                        return @login
                    end
                    def login=(l)
                        @login = l
                    end
                    def password
                        return @password
                    end
                    def password=(p)
                        @password = p
                    end
                end
            }
            Twitter.class_eval(c)
            ModClient.configure do |conf|
                conf.user_agent = 'mod_spox twitter for twits'
                conf.application_name = 'mod_spox IRC bot'
                conf.application_version = "#{$BOTVERSION} (#{$BOTCODENAME})"
                conf.application_url = 'http://rubyforge.org/projects/mod_spox'
                conf.source = 'modspoxircbot'
            end
        rescue Object => boom
            Logger.warn("Failed to load Twitter4R. Install gem to use Twitter plugin. (#{boom})")
            raise Exceptions::BotException.new('Failed to locate required gem: Twitter4R')
        end
        twitter = Models::Group.find_or_create(:name => 'twitter')
        admin = Models::Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'tweet (.+)', :method => :tweet, :group => twitter, :desc => 'Send a tweet', :params => [:message])
        add_sig(:sig => 'twitter auth( (\S+) (\S+))?', :method => :auth, :group => admin, :desc => 'Set/view authentication information',
                :params => [:info, :username, :password], :req => 'private')
        add_sig(:sig => 'twitter search (.+)', :method => :search, :desc => 'Basic twitter search', :params => [:term])
        add_sig(:sig => 'twitter asearch (.+)', :method => :advanced_search, :desc => 'Advanced search (http://apiwiki.twitter.com/Search-API-Documentation#Search)',
                :params => [:term])
        add_sig(:sig => 'twitter followers( \S+)?', :method => :followers, :desc => 'Show followers', :params => [:twit])
        add_sig(:sig => 'twitter friends( \S+)?', :method => :friends, :desc => 'Show friends', :params => [:twit])
        add_sig(:sig => 'twitter friend (\S+)', :method => :add_friend, :desc => 'Add a friend', :params => [:twit], :group => admin)
        add_sig(:sig => 'twitter unfriend (\S+)', :method => :remove_friend, :desc => 'Remove a friend', :params => [:twit], :group => admin)
        add_sig(:sig => 'twitter info', :method => :info, :desc => 'Show twitter info')
        add_sig(:sig => 'twit (\S+) (.+)', :method => :twat, :group => twitter, :desc => 'Send a direct tweet to twit', :params => [:twit, :message])
        add_sig(:sig => 'twit inbox', :method => :inbox, :group => twitter, :desc => 'Show inbox contents')
        add_sig(:sig => 'twitter del (\d+)', :method => :inbox_del, :group => twitter, :desc => 'Delete direct message from twitter', :params => [:m_id])
        add_sig(:sig => 'tweets del (\d+)', :method => :tweets_del, :group => twitter, :desc => 'Delete a status message from twitter', :params => [:m_id])
        add_sig(:sig => 'tweets (\d+)', :method => :tweets, :desc => 'Get a given message or the current message', :params => [:m_id])
        add_sig(:sig => 'autotweets ?(on|off)?', :method => :auto_tweets, :desc => 'Turn on/off auto tweet for a channel', :params => [:action],
                :group => admin, :req => 'public')
        add_sig(:sig => 'autotweets interval( \d+)?', :method => :auto_tweets_interval, :desc => 'Set/show interval for auto tweet checks',
                :group => admin, :params => [:interval])
        add_sig(:sig => 'autotweets burst( \d+)?', :method => :auto_tweets_burst, :desc => 'Set/show maximum number of tweets to display at once',
                :group => admin, :params => [:burst])
        add_sig(:sig => 'twitter alias (\S+) (\S+)', :method => :alias_user, :desc => 'Set alias for twitter account', :group => twitter, :params => [:twit, :irc])
        add_sig(:sig => 'twitter aliases (\S+)', :method => :show_aliases, :desc => 'Show alias for twit', :params => [:twit])
        add_sig(:sig => 'twitter dealias (\S+)', :method => :remove_alias, :desc => 'Remove alias for twit', :params => [:twit], :group => twitter)
        @pipeline.hook(self, :get_timer, :Internal_TimerResponse)
        @auth_info = Models::Setting.find_or_create(:name => 'twitter').value
        @twitter = ModClient.new
        @search_url = 'http://search.twitter.com/search.json'
        @aliases = Models::Setting.find_or_create(:name => 'twitter_aliases').value
        @aliases = {} if @aliases.nil?
        @burst = Models::Setting.find_or_create(:name => 'twitter_burst').value
        @burst = @burst.nil? ? 5 : @burst.to_i
        unless(@auth_info.is_a?(Hash))
            @auth_info = {:username => nil, :password => nil, :interval => 0, :channels => []}
        else
            connect if @twitter.authenticate?(@auth_info[:username], @auth_info[:password])
        end
        @last_check = Time.now
        @lock = Mutex.new
        @running = false
        @timer = {:action => nil, :id => nil}
        @friends = []
        populate_friends
        start_auto
    end

    def auto_tweets_burst(m, params)
        if(params[:burst])
            params[:burst] = params[:burst].to_i
            if(params[:burst] == 0)
                error m.replyto, 'Invalid value. Must supply a positive integer.'
            else
                @burst = params[:burst]
                information m.replyto, "Updated maximum autotweet burst to: #{@burst}"
            end
        else
            information m.replyto, "Maximum number of tweets to auto report: #{@burst}"
        end
    end
    
    def alias_user(m, params)
        begin
            raise "twit #{params[:twit]} is not in my friends list" unless @friends.include?(params[:twit])
            raise "twit is already aliased to #{Models::Nick[@aliases[params[:twit].to_sym]].nick}" if @aliases.has_key?(params[:twit].to_sym)
            nick = Helpers.find_model(params[:irc])
            raise "failed to find nick #{params[:irc]}. is this a new user?" if nick.nil?
            @aliases[params[:twit].to_sym] = nick.pk
            save_aliases
            information m.replyto, "Nick #{params[:irc]} is now aliased to twit #{params[:twit]}"
        rescue Object => boom
            error m.replyto, "Failed to alias user: #{boom}"
        end
    end
    
    def save_aliases
        t = Models::Setting.find_or_create(:name => 'twitter_aliases')
        t.value = @aliases
        t.save
    end
    
    def show_aliases(m, params)
        begin
            raise "twit #{params[:twit]} has no alias" unless @aliases.has_key?(params[:twit].to_sym)
            information m.replyto, "Twit #{params[:twit]} is aliased to: #{Models::Nick[@aliases[params[:twit].to_sym]].nick}"
        rescue Object => boom
            error m.replyto, "Failed to find alias. Reason: #{boom}"
        end
    end
    
    def remove_alias(m, params)
        begin
            raise "twit #{params[:twit]} has no alias" unless @aliases.has_key?(params[:twit].to_sym)
            @aliases.delete(params[:twit].to_sym)
            save_aliases
            information m.replyto, "Twit #{params[:twit]} is no longer aliased"
        rescue Object => boom
            error m.replyto, "Failed to remove alias: #{boom}"
        end
    end
    
    def search(m, params)
        url = URI.escape("#{@search_url}?rpp=1&q=#{params[:term]}")
        reply m.replyto, do_search(url, params[:term])
    end
    
    def advanced_search(m, params)
        opt = {:lang => nil, :rpp => 1, :page => 1, :since_id => nil}
        term = params[:term]
        opt.keys.each do |sym|
            if(term =~ /\b#{sym.to_s}:(\S+)\b/)
                opt[sym] = $1
                term.sub!(/#{sym.to_s}:\S+/, '')
            end
        end
        opt[:rpp] = 5 if opt[:rpp].to_i > 5
        opt[:rpp] = 1 if opt[:rpp].to_i < 1
        term.gsub!(/\s{2,}/, ' ')
        url = URI.escape("#{@search_url}?q=#{term}&#{opt.to_a.map{|a| "#{a[0]}=#{a[1]}"}.join('&')}")
        reply m.replyto, do_search(url, term)
    end
    
    def do_search(url, term)
        begin
            buf = open(url, 'UserAgent' => 'mod_spox IRC bot').read
            result = JSON.parse(buf)
            output = ["Twitter match for: \2#{term}:\2"]
            result['results'].each do |item|
                t = Time.parse(item['created_at'])
                output << "[#{t.strftime("%Y/%m/%d-%H:%M:%S")}] <#{item['from_user']}> #{Helpers.convert_entities(item['text'])}"
            end
            if(output.size < 2)
                output = "\2Error:\2 No results found for term: #{term}"
            end
            return output
        rescue Object => boom
            return "\2Error:\2 Failed to receive search results (over quota?)"
        end
    end
    
    def inbox(m, params)
        msgs = @twitter.messages(:received)
        reply m.replyto, "\2Twitter INBOX\2 Messages in inbox: #{msgs.size} (only last 5 displayed)"
        msgs.slice(0..5).each do | msg |
            reply m.replyto, "\2#{msg.sender.screen_name}:\2 [#{msg.id}] #{Helpers.convert_entities(msg.text)}"
        end
    end
    
    def inbox_del(m, params)
        begin
            @twitter.message(:delete, params[:m_id])
            information m.replyto, "message with ID: #{params[:m_id]} has been deleted"
        rescue Object => boom
            warning m.replyto, "failed to delete message with ID: #{params[:m_id]}"
        end
    end
    
    def tweets_del(m, params)
        begin
            @twitter.status(:delete, params[:m_id])
            information m.replyto, "message with ID: #{params[:m_id]} has been deleted"
        rescue Object => boom
            warning m.replyto, "failed to delete status message with ID: #{params[:m_id]}"
        end
    end
    
    def info(m, params)
        unless(@auth_info[:username].nil?)
            information m.replyto, "http://twitter.com/#{@auth_info[:username]}"
        else
            warning m.replyto, 'currently not configured'
        end
    end
    
    def auto_tweets_interval(m, params)
        if(params[:interval])
            int = params[:interval].strip.to_i
            @auth_info[:interval] = int
            save_info
            update_auto
            information m.replyto, "auto tweet interval updated to: #{int > 0 ? int : 'stopped'}"
        else
            information m.replyto, "auto tweet interval is: #{@auth_info[:interval] > 0 ? "#{@auth_info[:interval]} seconds" : 'stopped'}"
        end
    end
    
    def auto_tweets(m, params)
        if(params[:action])
            on = @auth_info[:channels].include?(m.target.id)
            if(params[:action] == 'on')
                if(on)
                    warning m.replyto, 'this channel is already enabled for auto tweets'
                else
                    @auth_info[:channels] << m.target.id
                    save_info
                    update_auto
                    information m.replyto, 'auto tweets are now enabled for this channel'
                end
            else
                if(on)
                    @auth_info[:channels].delete(m.target.id)
                    save_info
                    update_auto
                    information m.replyto, 'auto tweets are now disabled for this channel'
                else
                    warning m.replyto, 'this channel is not currently enabled for auto tweets'
                end
            end
        else
            information m.replyto, "auto tweets currently enabled in: #{@auth_info[:channels].size > 0 ? @auth_info[:channels].map{|i| Models::Channel[i].name}.join(', ') : 'not enabled'}"
        end
    end
    
    def auth(m, params)
        if(params[:info])
            begin
                @auth_info[:username] = params[:username]
                @auth_info[:password] = params[:password]
                @twitter.authenticate?(params[:username], params[:password])
                save_info
                information m.replyto, 'Authentication information has been updated'
            rescue Object => boom
                error m.replyto, "Failed to save authentication information: #{boom}"
            end
        else
            information m.replyto, "username -> #{@auth_info[:username].nil? ? 'unset' : @auth_info[:username]} password -> #{@auth_info[:password].nil? ? 'unset' : @auth_info[:password]}"
        end
    end
    
    def tweet(m, params)
        begin
            @twitter.status(:post, params[:message])
            information m.replyto, 'tweet has been sent'
        rescue Object => boom
            error m.replyto, "failed to send tweet. (#{boom})"
        end
    end
    
    def twat(m, params)
        begin
            user = @twitter.user(params[:twit])
            @twitter.message(:post, params[:message], user)
            information m.replyto, 'tweet has been sent'
        rescue Object => boom
            error m.replyto, "failed to send tweet. (#{boom})"
        end
    end
    
    def followers(m, params)
        begin
            fs = @twitter.my(:followers)
            if(fs.size > 0)
                reply m.replyto, "\2Followers:\2 #{fs.map{|u| u.screen_name}.join(', ')}"
            else
                warning m.replyto, 'no followers found'
            end
        rescue Object => boom
            error m.replyto, "failed to locate followers list. (#{boom})"
        end
    end
    
    def friends(m, params)
        if(@friends.size > 0)
            reply m.replyto, "\2Friends:\2 #{@friends.join(', ')}"
        else
            warning m.replyto, 'no friends found'
        end
    end
    
    def add_friend(m, params)
        begin
            user = @twitter.user(params[:twit])
            unless(@twitter.my(:friends).include?(user))
                @twitter.friend(:add, user)
                information m.replyto, "added new friend: #{params[:twit]}"
                @friends << params[:twit]
            else
                warning m.replyto, "#{params[:twit]} is already in friend list"
            end
        rescue Object => boom
            error m.replyto, "failed to add friend #{params[:twit]}. (#{boom})"
        end
    end
    
    def remove_friend(m, params)
        begin
            user = @twitter.user(params[:twit])
            if(@twitter.my(:friends).map{|u|u.screen_name}.include?(user.screen_name))
                @twitter.friend(:remove, user)
                information m.replyto, "removed user from friend list: #{params[:twit]}"
                @friends.delete(params[:twit])
            else
                warning m.replyto, "#{params[:twit]} is not in friend list"
            end
        rescue Object => boom
            error m.replyto, "failed to remove friend #{params[:twit]}. (#{boom})"
        end
    end
    
    def tweets(m, params)
        begin
            msg = @twitter.status(:get, params[:m_id])
            if(msg)
                reply m.replyto, "\2Tweet:\2 [#{msg.created_at.strftime("%Y/%m/%d-%H:%M:%S")}}] <#{screen_name(msg.user.screen_name)}> #{Helpers.convert_entities(msg.text)}"
            else
                warning m.replyto, "failed to find message with ID: #{params[:m_id].strip}"
            end
        rescue Object => boom
            error m.replyto, "error encountered while attempting to fetch message. (#{boom})"
        end
    end
    
    private
    
    def populate_friends
        return unless @lock.try_lock
        begin
            fs = @twitter.my(:friends)
            @friends = []
            if(fs.size > 0)
                @friends = fs.map{|u| u.screen_name}
            end
        rescue Object => boom
            Logger.info("Failed to populate friends: #{boom}")
            @pipeline << Messages::Internal::TimerAdd.new(self, 200, nil, true){ populate_friends }
        ensure
            @lock.unlock
        end
    end
    
    def screen_name(n)
        return @aliases.has_key?(n.to_sym) ? Models::Nick[@aliases[n.to_sym]].nick : n
    end
    
    def check_timeline
        if(@auth_info[:channels].size < 1 || @auth_info[:interval].to_i < 1)
            Logger.warn('Twitter has no channels to send information to')
        else
            begin
                things = []
                @twitter.my(:friends).each do |f|
                    @twitter.timeline_for(:friend, :id => f.screen_name, :since => @last_check) do |status|
                        next if status.created_at < @last_check
                        if(Helpers.convert_entities(status.text) =~ /^@(\S+)/)
                            next unless @twitter.my(:friends).map{|f|f.screen_name}.include?($1) || $1 == @twitter.login
                        end
                        things << "[#{status.created_at.strftime("%H:%M:%S")}] <#{screen_name(status.user.screen_name)}> #{Helpers.convert_entities(status.text)}"
                    end
                end
                @twitter.timeline_for(:me, :since => @last_check) do |status|
                    next if status.created_at < @last_check
                    things << "[#{status.created_at.strftime("%H:%M:%S")}] <#{screen_name(status.user.screen_name)}> #{Helpers.convert_entities(status.text)}"
                end
                things.uniq!
                things.sort!
                things = things[-@burst,@burst] if things.size > @burst
                things.each do |status|
                    @auth_info[:channels].each{|i| reply Models::Channel[i], "\2AutoTweet:\2 #{status}"}
                end
                @last_check = Time.now
            rescue Object => boom
                Logger.warn("Twitter encountered an error during autotweets check: #{boom}")
            end
        end
    end
    
    def save_info
        i = Models::Setting.find_or_create(:name => 'twitter')
        i.value = @auth_info
        i.save
    end
    
    def connect
        @twitter.login = @auth_info[:username]
        @twitter.password = @auth_info[:password]
    end
    
    def get_timer(m)
        if(m.id == @timer[:id])
            @timer[:action] = m.action_added? ? m.action : nil
        end
    end
    
    def update_auto
        if(@auth_info[:interval] > 0 && !@auth_info[:channels].empty?)
            @pipeline << Messages::Internal::TimerRemove.new(@timer[:action]) if @timer[:action].nil?
            start_auto
        else
            @pipeline << Messages::Internal::TimerRemove.new(@timer[:action]) unless @timer[:action].nil?
        end 
    end
    
    def start_auto
        if(@auth_info[:interval] > 0 && @timer[:action].nil?)
            m = Messages::Internal::TimerAdd.new(self, @auth_info[:interval].to_i){ check_timeline }
            @timer[:id] = m.id
            @pipeline << m
        end
    end

end