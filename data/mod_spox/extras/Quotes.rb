class Quotes < ModSpox::Plugin

    include Models
    
    def initialize(pipeline)
        super
        Quote.create_table unless Quote.table_exists?
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