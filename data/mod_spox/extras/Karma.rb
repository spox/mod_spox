class Karma < ModSpox::Plugin

    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        KarmaDatatype::Karma.create_table unless KarmaDatatype::Karma.table_exists?
        Models::Signature.find_or_create(:signature => 'karma (\S+)', :plugin => name, :method => 'score', :description => 'Returns karma for given thing').params = [:thing]
        Models::Signature.find_or_create(:signature => 'karma reset (\S+)', :plugin => name, :method => 'reset',
            :group_id => Models::Group.filter(:name => 'admin').first.pk, :description => 'Reset a karma score').params = [:thing]
        @pipeline.hook(self, :check, :Incoming_Privmsg)
        @thing_maxlen = 32
        @karma_regex = /(\(.{1,#@thing_maxlen}?\)|\S{1,#@thing_maxlen})([+-]{2})(?:\s|$)/
    end

    def check(message)
        if(message.is_public?)
            message.message.scan(@karma_regex) do |match|
                thing, adj = match
                thing.downcase!
                thing = thing[1..-2] if thing[0..0] == '(' && thing[-1..1] == ')'
                adj = adj == '++' ? +1 : -1
                karma = KarmaDatatype::Karma.find_or_create(:thing => thing, :channel_id => message.target.pk)
                karma.set(:score => karma.score + adj)
            end
        end
    end
    
    def score(message, params)
        params[:thing].downcase!
        return unless message.is_public?
        karma = KarmaDatatype::Karma.filter(:thing => params[:thing], :channel_id => message.target.pk).first
        if(karma)
            @pipeline << Privmsg.new(message.replyto, "Karma for \2#{karma.thing}\2 is #{karma.score}")
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 #{params[:thing]} has no karma")
        end
    end
    
    def reset(message, params)
        params[:thing].downcase!
        return unless message.is_public?
        karma = KarmaDatatype::Karma.filter(:thing => params[:thing], :channel_id => message.target.pk).first
        if(karma)
            karma.set(:score => 0)
            @pipeline << Privmsg.new(message.replyto, "Karma for \2#{karma.thing}\2 has been reset")
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 #{params[:thing]} has no karma")
        end        
    end

end

module KarmaDatatype
    class Karma < Sequel::Model
        set_schema do
            primary_key :id
            text :thing, :null => false, :unique => true
            integer :score, :null => false, :default => 0
            foreign_key :channel_id, :table => :channels
        end
        
        def channel
            ModSpox::Models::Channel[channel_id]
        end
    end
end