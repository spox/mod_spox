class Fortune < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'fortune( \S+)?', :method => :fortune, :desc => 'Get a fortune', :params => [:type])
        add_sig(:sig => 'fortunes', :method => :show_groups, :desc => 'Show available fortune types')
        add_sig(:sig => 'fortunes count( \S+)?', :method => :count, :desc => 'Count fortunes', :params => [:type])
        @fetching = false
        @db = nil
        unless(File.exists?(BotConfig[:userpath] + '/fortunes.db.sql3'))
            @fetching = true
            do_fetch
        else
            @db = Sequel.sqlite(BotConfig[:userpath] + '/fortunes.db.sql3')
        end
    end

    def count(m, params)
        unless(@fetching)
            output = nil
            if(params[:type])
                params[:type].strip!
                output = "Number of fortunes (type #{params[:type]}): #{@db[:fortunes].filter(:type => params[:type]).count}"
            else
                output = "Number of fortunes: #{@db[:fortunes].count}"
            end
            information m.replyto, output
        else
            error m.replyto, "Waiting for fortunes to complete download"
        end
    end
    
    def show_groups(m, params)
        unless(@fetching)
            information m.replyto, "Fortune types available: #{@db[:fortunes].distinct(:type).map(:type).join(', ')}"
        else
            error m.replyto, "Waiting for fortunes to complete download"
        end
    end
    
    def fortune(m, params)
        unless(@fortune)
            ids = nil
            if(params[:type])
                params[:type].strip!
                ids = @db[:fortunes].filter(:type => params[:type]).map(:id)
            else
                ids = @db[:fortunes].map(:id)
            end
            f = @db[:fortunes].filter(:id => ids[rand(ids.size)]).first
            reply m.replyto, f[:fortune]
        else
            error m.replyto, "Waiting for fortunes to complete download"
        end
    end

    private

    def do_fetch
        Thread.new do
            `wget --output-document=#{BotConfig[:userpath]}/fortunes.tar.gz http://rubyforge.org/frs/download.php/59569/fortunes.tar.gz`
            `tar -C #{BotConfig[:userpath]} -xzf #{BotConfig[:userpath]}/fortunes.tar.gz`
            @fetching = false
            @db = Sequel.sqlite(BotConfig[:userpath] + '/fortunes.db.sql3')
        end
    end
end