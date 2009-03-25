require 'net/http'
require 'digest/md5'
require 'cgi'


# IMPORTANT NOTE: This plugin requires installation of the HTMLEntities gem 
class Confess < ModSpox::Plugin

    include Models
    
    def initialize(pipeline)
        super(pipeline)
        begin
            Confession.db = Sequel.sqlite(BotConfig[:userpath] + '/confessions.db')
        rescue Object => boom
            Logger.warn("Error: Unable to initialize this plugin: #{boom}")
            raise Exceptions::BotException.new("Failed to create database: #{boom}")
        end
        Confession.build_confession && Confession.create_table unless Confession.table_exists?
        add_sig(:sig => 'confess', :method => :confess, :desc => 'Print a confession')
        add_sig(:sig => 'confess (?!score|count|fetcher|\+\+|\-\-)(.+)?', :method => :confess, :desc => 'Print a confession', :params => [:term])
        add_sig(:sig => 'confess(\+\+|\-\-) ?(\d+)?', :method => :score, :desc => 'Score a confession', :params => [:score, :id])
        add_sig(:sig => 'confess score (\d+)', :method => :show_score, :desc => 'Show a confession\'s score', :params => [:id])
        add_sig(:sig => 'confess count', :method => :count, :desc => 'Current count of cached confessions')
        add_sig(:sig => 'confess fetcher (start|stop)', :method => :fetcher, :desc => 'Turn confession fetcher on or off', :group => Group.filter(:name => 'admin').first, :params => [:status])
        Config[:confess] = 'nofetch' if Config[:confess].nil?
        @last_confession = {}
        @fetch = false
        @timer = {:action => nil, :id => nil}
        @lock = Mutex.new
        start_fetcher if Config[:confess] == 'fetch'
    end
    
    def destroy
        Confession.db.disconnect
    end
    
    def confess(message, params)
        begin
            c = nil
            pk = nil
            @lock.synchronize do
                if(params[:term])
                    return if params[:term] == 'count'
                    if(params[:term] =~ /^\d+$/)
                        c = Confession[params[:term].to_i]
                    else
                        cs = Confession.search(params[:term])
                        Logger.info("Size of confession results: #{cs.size}")
                        rand_idx = rand(cs.size - 1)
                        rand_id = cs[rand_idx].to_i
                        Logger.info("Random index to be used: #{rand_idx}")
                        Logger.info("Random ID to be used for confession: #{rand_id}")
                        c = Confession[rand_id]
                    end
                else
                    c = Confession[rand(Confession.count) - 1]
                end
                unless c.nil?
                    pk = c.pk
                    c = c.confession
                end
            end
            if(c)
                reply message.replyto, "\2[#{pk}]\2: #{c}"
                @last_confession[message.target.pk] = pk
            else
                reply message.replyto, "\2Error:\2 Failed to find confession"
            end
        rescue Object => boom
            reply message.replyto, "Failed to locate a match. Error encountered: #{boom}"
        end
    end
    
    def show_score(message, params)
        pk = nil
        score = nil
        c = nil
        @lock.synchronize do
            c = Confession[params[:id].to_i]
            if(c)
                pk = c.pk
                score = c.score.to_i
            end
        end
        if(pk)
            reply message.replyto, "\2[#{pk}]:\2 #{score}% of raters gave this confession a positive score"
        else
            reply message.replyto, "\2Error:\2 Failed to find confession with ID: #{params[:id]}"
        end
    end
    
    def score(message, params)
        c = nil
        @lock.synchronize do
            if(params[:id])
                c = Confession[params[:id].to_i]
            else
                c = Confession[@last_confession[message.target.pk]] if @last_confession.has_key?(message.target.pk)
            end
        end
        if(c)
            @lock.synchronize do
                if(params[:score] == '++')
                    c.update_with_params(:positive => c.positive.to_i + 1)
                else
                    c.update_with_params(:negative => c.negative.to_i + 1)
                end
                c.update_with_params(:score => ((c.positive.to_f) / (c.positive.to_f + c.negative.to_f)) * 100.0)
            end
        else
            reply message.replyto, "\2Error:\2 Failed to find confession to score"
        end
    end
    
    def count(message, params)
        c = 0
        @lock.synchronize do
            c = Confession.count
        end
        reply message.replyto, "Current number of stored confessions: #{c}"
    end
    
    def fetcher(message, params)
        if(params[:status] == 'start')
            if(Config[:confess] == 'fetch')
                reply message.replyto, 'Confession fetcher is already running'
            else
                Config[:confess] = 'fetch'
                reply message.replyto, 'Confession fetcher is now running'
                start_fetcher
            end
        else
            if(Config[:confess] == 'fetch')
                Config[:confess] = 'nofetch'
                stop_fetcher
                reply message.replyto, 'Confession fetcher has been stopped'
            else
                reply message.replyto, 'Confession fetcher is not currently running'
            end
        end
    end
    
    def grab_page
        begin
            connection = Net::HTTP.new('www.grouphug.us', 80)
            response = connection.request_get("/frontpage?page=#{rand(17349)+1}", nil)
            response.value
            page = response.body.gsub(/[\r\n]/, ' ')
            Logger.info("Processing matches")
            page.scan(/<div class="content">\s*<p>\s*(.+?)\s*<\/p>\s*<\/div>/).each{|match|
                Logger.info("Match found: #{match[0]}")
                conf = CGI::unescapeHTML(match[0])
                conf = conf.gsub(/<.+?>/, ' ').gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
                conf = Helpers.convert_entities(conf)
                Logger.info("Match turned into: #{conf}")
                if conf.length < 300
                    begin
                        @lock.synchronize do
                            c = Confession.new(:hash => Digest::MD5.hexdigest(conf)).save
                            c.confession = conf 
                        end
                    rescue Object => boom
                        Logger.warn('Warning: Fetched confession already found in database')
                    end
                end
            }
        rescue Object => boom
            Logger.warn("Error fetching data: #{boom}")
        ensure
            @timer[:action].reset_period(rand(1000)+1) unless @timer[:action].nil?
        end
    end
    
    private
    
    def start_fetcher
        if(@timer[:action].nil?)
            m = Messages::Internal::TimerAdd.new(self, rand(1000)+1){ grab_page }
            @timer[:id] = m.id
            @pipeline << m
        end
    end
    
    def get_timer(m)
        if(m.id == @timer[:id])
            if(m.action_added?)
                @timer[:action] = m.action
            else
                @timer = {:action => nil, :id => nil}
            end
        end
    end
    
    def stop_fetcher
        unless(@timer[:action].nil?)
            @pipeline << Messages::Internal::TimerRemove(@timer[:action])
        end
    end

    class Confession < Sequel::Model    
        def Confession.build_confession
            db << 'CREATE VIRTUAL TABLE `confessions_confession` USING FTS3(`confession` TEXT NOT NULL)'
        end
        
        set_schema do
            text :hash, :null => false, :unique => true
            integer :positive, :null => false, :default => 0
            integer :negative, :null => false, :default => 0
            float :score, :null => false, :default => 0
            primary_key :id
        end
        
        def confession=(c)
            if(confession)
                db[:confessions_confession].filter('docid = ?', pk).update(:confession => c)
            else
                db[:confessions_confession] << {:docid => pk, :confession => c}
            end
        end
        
        def confession
            c = db[:confessions_confession].select(:confession).where('docid = ?', pk).first
            return c.nil? ? nil : c[:confession]
        end
        
        def Confession.search(terms)
            results = db['select docid from confessions_confession where confession match ?', terms].map(:docid)
        end
    end

end