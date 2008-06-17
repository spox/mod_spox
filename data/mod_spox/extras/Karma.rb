class Karma < ModSpox::Plugin

    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        Datatype::Karma.create_table unless Datatype::Karma.table_exists?
        Datatype::Alias.create_table unless Datatype::Alias.table_exists?
        Models::Signature.find_or_create(:signature => 'karma (\S+)', :plugin => name, :method => 'score', :description => 'Returns karma for given thing').params = [:thing]
        Models::Signature.find_or_create(:signature => 'karma reset (\S+)', :plugin => name, :method => 'reset',
            :group_id => Models::Group.filter(:name => 'admin').first.pk, :description => 'Reset a karma score').params = [:thing]
        Models::Signature.find_or_create(:signature => 'karma alias (\S+) (\S+)', :plugin => name, :method => 'aka',
            :group_id => Models::Group.find_or_create(:name => 'alias').pk, :description => 'Alias a karma object to another karma object').params = [:thing, :thang]
        Models::Signature.find_or_create(:signature => 'karma fight (\S+) (\S+)', :plugin => name, :method => 'fight',
            :description => 'Make two karma objects fight').params = [:thing, :thang]
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
                karma = Datatype::Karma.find_or_create(:thing => thing, :channel_id => message.target.pk)
                karma.update_with_params(:score => karma.score + adj)
            end
        end
    end
    
    def score(message, params)
        params[:thing].downcase!
        return unless message.is_public?
        karma = Datatype::Karma.filter(:thing => params[:thing], :channel_id => message.target.pk).first
        if(karma)
            @pipeline << Privmsg.new(message.replyto, "Karma for \2#{karma.thing}\2 is #{Datatype::Alias.score_object(karma.pk)}")
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 #{params[:thing]} has no karma")
        end
    end
    
    def reset(message, params)
        params[:thing].downcase!
        return unless message.is_public?
        karma = Datatype::Karma.filter(:thing => params[:thing], :channel_id => message.target.pk).first
        if(karma)
            karma.update_with_params(:score => 0)
            @pipeline << Privmsg.new(message.replyto, "Karma for \2#{karma.thing}\2 has been reset")
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 #{params[:thing]} has no karma")
        end        
    end
    
    def fight(message, params)
        thing = Datatype::Karma.find_or_create(:thing => params[:thing])
        thang = Datatype::Karma.find_or_create(:thing => params[:thang])
        thing_score = Datatype::Alias.score_object(thing.pk)
        thang_score = Datatype::Alias.score_object(thang.pk)
        winner = thing_score > thang_score ? params[:thing] : params[:thang]
        loser = thing_score > thang_score ? params[:thang] : params[:thing]
        distance = (thing_score - thang_score).abs
        reply message.replyto, "\2KARMA FIGHT RESULTS:\2 \2#{winner}\2 has beaten \2#{loser}\2 by a #{distance} point lead"
    end
    
    def aka(message, params)
        thing = Datatype::Karma.find_or_create(:thing => params[:thing].downcase, :channel_id => message.target.pk)
        thang = Datatype::Karma.find_or_create(:thing => params[:thang].downcase, :channel_id => message.target.pk)
        if(Datatype::Alias.filter('(thing_id = ? AND aka_id = ?) OR (thing_id = ? AND aka_id = ?)', thing.pk, thang.pk, thang.pk, thing.pk).first)
            reply message.replyto, "\2Error:\2 #{params[:thing]} is already aliased to #{params[:thang]}"
        else
            Datatype::Alias.find_or_create(:thing_id => thing.pk, :aka_id => thang.pk)
            reply message.replyto, "\2Karma Alias:\2 #{params[:thing]} is now aliased to #{params[:thang]}"
        end
    end 

    module Datatype
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
        class Alias < Sequel::Model
            set_schema do
                primary_key :id
                foreign_key :thing_id, :null => false
                foreign_key :aka_id, :null => false
            end
            
            def thing
                Karma[thing_id]
            end
            
            def aka
                Karma[aka_id]
            end
            
            def Alias.score_object(object_id)
                object = Karma[object_id]
                score = object.nil? ? 0 : object.score
                Alias.filter(:thing_id => object_id).each do |ali|
                    score += ali.aka.score
                end
                Alias.filter(:aka_id => object_id).each do |ali|
                    score += ali.thing.score
                end
                return score
            end
        end
    end
end