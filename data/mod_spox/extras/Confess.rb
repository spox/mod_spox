require 'net/http'
require 'digest/md5'
require 'cgi'


# IMPORTANT NOTE: This plugin requires installation of the HTMLEntities gem 
class Confess < ModSpox::Plugin

    include Models
    
    def initialize(pipeline)
        super(pipeline)
        begin
            require 'htmlentities'
        rescue Object => boom
            Logger.warn('Error: This plugin requires the HTMLEntities gem. Please install and reload plugin.')
            raise Exceptions::BotException.new("Missing required HTMLEntities library")
        end
        Confession.create_table unless Confession.table_exists?
        Signature.find_or_create(:signature => 'confess ?(?!score|count|fetcher|\+\+|\-\-)(.+)?', :plugin => name, :method => 'confess',
            :description => 'Print a confession').params = [:term]
        Signature.find_or_create(:signature => 'confess(\+\+|\-\-) ?(\d+)?', :plugin => name, :method => 'score',
            :description => 'Score a confession').params = [:score, :id]
        Signature.find_or_create(:signature => 'confess score (\d+)', :plugin => name, :method => 'show_score',
            :description => 'Show a confession\'s score').params = [:id]
        Signature.find_or_create(:signature => 'confess count', :plugin => name, :method => 'count',
            :description => 'Current count of cached confessions')
        Signature.find_or_create(:signature => 'confess fetcher (start|stop)', :plugin => name, :method => 'fetcher',
            :description => 'Turn confession fetcher on or off', :group_id => Group.filter(:name => 'admin').first.pk).params = [:status]
        Config[:confess] = 'nofetch' if Config[:confess].nil?
        @last_confession = {}
        @fetch = false
        @mutex = Mutex.new
        @coder = HTMLEntities.new
        start_fetcher if Config[:confess] == 'fetch'
    end
    
    def confess(message, params)
        c = nil
        if(params[:term])
            return if params[:term] == 'count'
            if(params[:term] =~ /^\d+$/)
                c = Confession[params[:term].to_i]
             else
                 cs = Database.db[:confessions].full_text_search(:confession, params[:term].gsub(/\s+/, '.*'), :language => 'english').map(:id)
                 c = Confession[cs[rand(cs.size)].to_i]
             end
        else
            c = Confession[rand(Confession.count) + 1]
        end
        if(c)
            reply message.replyto, "\2[#{c.pk}]\2: #{c.confession}"
            @last_confession[message.target.pk] = c.pk
        else
            reply message.replyto, "\2Error:\2 Failed to find confession"
        end
    end
    
    def show_score(message, params)
        c = Confession[params[:id].to_i]
        if(c)
            reply message.replyto, "\2[#{c.pk}]:\2 #{c.score.to_i}% of raters gave this confession a positive score"
        else
            reply message.replyto, "\2Error:\2 Failed to find confession with ID: #{params[:id]}"
        end
    end
    
    def score(message, params)
        if(params[:id])
            c = Confession[params[:id].to_i]
        else
            c = Confession[@last_confession[message.target.pk]] if @last_confession.has_key?(message.target.pk)
        end
        if(c)
            if(params[:score] == '++')
                c.update_with_params(:positive => c.positive.to_i + 1)
            else
                c.update_with_params(:negative => c.negative.to_i + 1)
            end
            c.update_with_params(:score => ((c.positive.to_f) / (c.positive.to_f + c.negative.to_f)) * 100.0)
        else
            reply message.replyto, "\2Error:\2 Failed to find confession to score"
        end
    end
    
    def count(message, params)
        reply message.replyto, "Current number of stored confessions: #{Confession.count}"
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
                reply message.replyto, 'Confession fetcher has been stopped'
            else
                reply message.replyto, 'Confession fetcher is not currently running'
            end
        end
    end
    
    def grab_page
        begin
            connection = Net::HTTP.new('grouphug.us', 80)
            response = connection.request_get("/confessions/new?page=#{rand(17349)+1}", nil)
            response.value
            page = response.body.gsub(/[\r\n]/, ' ')
            Logger.info("Processing matches")
            page.scan(/<div class="content">\s*<p>\s*(.+?)\s*<\/p>\s*<\/div>/).each{|match|
                Logger.info("Match found: #{match[0]}")
                conf = CGI::unescapeHTML(match[0])
                conf = conf.gsub(/<.+?>/, ' ').gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
                conf = @coder.decode(conf)
                Logger.info("Match turned into: #{conf}")
                if conf.length < 300
                    begin
                        Confession.new(:confession => conf, :hash => Digest::MD5.hexdigest(conf)).save
                    rescue Object => boom
                        Logger.warn('Warning: Fetched confession already found in database')
                    end
                end
            }
        rescue Object => boom
            Logger.warn("Error fetching data: #{boom}")
        end
        if(Config[:confess] == 'fetch')
            @pipeline << Messages::Internal::TimerAdd.new(self, rand(500), nil, true){ grab_page }
        else
            stop_fetcher
        end
    end
    
    private
    
    def start_fetcher
        @mutex.synchronize do
            grab_page unless @fetch
        end
    end
    
    def stop_fetcher
        @mutex.synchronize do
            @fetch = false
        end
    end

    class Confession < Sequel::Model
        set_schema do
            text :confession, :null => false
            text :hash, :null => false, :unique => true
            integer :positive, :null => false, :default => 0
            integer :negative, :null => false, :default => 0
            float :score, :null => false, :default => 0
            primary_key :id
            full_text_index :confession
        end
    end

end