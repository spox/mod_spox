class Fortune < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'fortune( \S+)?', :method => :fortune, :desc => 'Get a fortune', :params => [:type])
        add_sig(:sig => 'fortunes', :method => :show_groups, :desc => 'Show available fortune types')
        add_sig(:sig => 'fortunes count( \S+)?', :method => :count, :desc => 'Count fortunes', :params => [:type])
        @fetching = false
        @db = nil
        @ids = {}
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
            information m.replyto, "Fortune types available: #{@db['select distinct(type) from fortunes order by type'].map(:type).join(', ')}"
        else
            error m.replyto, "Waiting for fortunes to complete download"
        end
    end
    
    def fortune(m, params)
        unless(@fortune)
            f = nil
            if(params[:type])
                t = params[:type].downcase.strip
                unless(@ids[t])
                    c = @db[:fortunes].filter(:type => t).map(:id)
                    @ids[t] = c unless c.empty?
                end
                f = @db[:fortunes].filter(:id => @ids[t][rand(@ids[t].size)]).first if @ids[t]
            else
                @ids[:all] = @db[:fortunes].count
                f = @db[:fortunes].filter(:id => rand(@ids[:all])).first
            end
            if(f)
                reply m.replyto, f[:fortune]
            else
                error m.replyto, "Failed to locate fortune"
            end
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