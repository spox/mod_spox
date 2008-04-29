class Quotes < ModSpox::Plugin

    include Models
    
    def initialize(pipeline)
        super
        Quote.create_table unless Quote.table_exists?
        group = Group.find_or_create(:name => 'quote')
        Signature.find_or_create(:signature => 'quote ?(.+)?', :plugin => name, :method => 'quote',
            :description => 'Display random quote, random quote containing search term, or quote with given ID').params = [:term]
        Signature.find_or_create(:signature => 'addquote (.+)', :plugin => name, :method => 'addquote',
            :description => 'Add a new quote').params = [:quote]
        Signature.find_or_create(:signature => 'searchquote (.+)', :plugin => name, :method => 'searchquote',
            :description => 'Return IDs of quotes matching term').params = [:term]
        Signature.find_or_create(:signature => 'delquote (\d+)', :plugin => name, :method => 'delquote', :group_id => group.pk,
            :description => 'Delete quote with given ID').params = [:id]
    end
    
    def quote(message, params)
        quote = nil
        reg = false
        if(params[:term])
            if(params[:term] =~ /^\d+$/)
                quote = Quote[params[:term].to_i]
            else
                quote = Quote.filter(:quote => Regexp.new(params[:term])).first
                reg = true
            end
        else
            ids = Quote.map(:id)
            quote = Quote[ids[rand(ids.size - 1)].to_i]
        end
        if(quote)
            reply message.replyto, "\2[\2#{quote.pk}\2|\2#{quote.added.year}/#{quote.added.month}/#{quote.added.day}\2]:\2 #{reg ? quote.quote.gsub(/(#{params[:term]})/, "\2\\1\2") : quote.quote}"
        else
            reply message.replyto, "\2Error:\2 Failed to find quote"
        end
    end
    
    def addquote(message, params)
        quote = Quote.new(:nick_id => message.source.pk, :channel_id => message.target.pk)
        quote.quote = params[:quote]
        quote.added = Time.now
        quote.save
        reply message.replyto, "\2Quote added:\2 ##{quote.pk}"
    end
    
    def searchquote(message, params)
        result = Quote.filter(:quote => Regexp.new(params[:term]))
        if(result.size > 0)
            ids = result.map(:id)
            ids.sort!
            ids = ids.slice(0, 20)
            reply message.replyto, "Quotes matching term (#{params[:term]}): #{ids.join(', ')}"
        else
            reply message.replyto, "\2Error:\2 No quotes match search term: #{params[:term]}"
        end
    end
    
    def delquote(message, params)
        result = Quote.filter(:id => params[:id].to_i)
        if(result.size < 1)
            reply message.replyto, "\2Error:\2 Failed to find quote with ID: #{params[:id]}"
        else
            result.destroy
            reply message.replyto, "\2Quote deleted:\2 ##{params[:id]}"
        end
    end
    
    class Quote < Sequel::Model
        set_schema do
            primary_key :id
            text :quote, :null => false
            timestamp :added, :null => false
            foreign_key :nick_id, :table => :nicks
            foreign_key :channel_id, :table => :channels
        end
    end
    
end