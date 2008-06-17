class Karma < ModSpox::Plugin

    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        Datatype::Karma.create_table unless Datatype::Karma.table_exists?
        Datatype::Alias.create_table unless Datatype::Alias.table_exists?
        alias_group = Models::Group.find_or_create(:name => 'alias')
        Models::Signature.find_or_create(:signature => 'karma (\S+)', :plugin => name, :method => 'score', :description => 'Returns karma for given thing').params = [:thing]
        Models::Signature.find_or_create(:signature => 'karma reset (\S+)', :plugin => name, :method => 'reset',
            :group_id => Models::Group.filter(:name => 'admin').first.pk, :description => 'Reset a karma score').params = [:thing]
        Models::Signature.find_or_create(:signature => 'karma alias (\S+) (\S+)', :plugin => name, :method => 'aka',
            :group_id => alias_group.pk, :description => 'Alias a karma object to another karma object').params = [:thing, :thang]
        Models::Signature.find_or_create(:signature => 'karma dealias (\S+) (\S+)', :plugin => name, :method => 'dealias',
            :group_id => alias_group.pk, :description => 'Remove a karma alias').params = [:thing, :otherthing]
        Models::Signature.find_or_create(:signature => 'karma aliases (\S+)', :plugin => name, :method => 'show_aliases',
            :description => 'Show all aliases for given thing').params = [:thing]
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
                karma.score = karma.score + adj
                karma.save
            end
        end
    end
    
    def score(message, params)
        return unless message.is_public?
        karma = Datatype::Karma.filter(:thing => params[:thing].downcase, :channel_id => message.target.pk).first
        if(karma)
            @pipeline << Privmsg.new(message.replyto, "Karma for \2#{params[:thing]}\2 is #{Datatype::Alias.score_object(karma.pk)}")
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
        thing = Datatype::Karma.find_or_create(:thing => params[:thing].downcase)
        thang = Datatype::Karma.find_or_create(:thing => params[:thang].downcase)
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
     
    def dealias(message, params)
        thing = Datatype::Karma.filter(:thing => params[:thing].downcase, :channel_id => message.target.pk).first
        otherthing = Datatype::Karma.filter(:thing => params[:otherthing].downcase, :channel_id => message.target.pk).first
        if(thing && otherthing)
            set = Datatype::Alias.filter('(thing_id = ? AND aka_id = ?) OR (thing_id = ? AND aka_id = ?)', thing.pk, otherthing.pk, otherthing.pk, thing.pk)
            if(set.size < 1)
                reply message.replyto, "\2Error:\2 No alias found between #{params[:thing]} and #{params[:otherthing]}"
            else
                set.destroy
                reply message.replyto, "#{params[:thing]} has been successfully dealiased from #{params[:otherthing]}"
            end
        else
            reply message.replyto, "\2Error:\2 No alias found between #{params[:thing]} and #{params[:otherthing]}"
        end
    end
    
    def show_aliases(message, params)
        thing = Datatype::Karma.filter(:thing => params[:thing].downcase, :channel_id => message.target.pk).first
        if(thing)
            things = []
            Datatype::Alias.get_aliases(thing.pk).each do |id|
                things << Datatype::Karma[id].thing
            end
            if(things.empty?)
                reply message.replyto, "#{params[:thing]} is not currently aliased"
            else
                reply message.replyto, "#{params[:thing]} is currently aliased to: #{things.join(', ')}"
            end
        else
            reply message.replyto, "\2Error:\2 #{params[:thing]} has never been used and has no aliases"
        end
    end

    module Datatype
        class Karma < Sequel::Model
            set_schema do
                primary_key :id
                text :thing, :null => false
                integer :score, :null => false, :default => 0
                foreign_key :channel_id, :table => :channels
                index [:thing, :channel_id], :unique => true
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
                Alias.create_lock unless class_variable_defined?(:@@lock)
                @@objects = []
                score = 0
                @@lock.synchronize do
                    score += Alias.sum_objects(object_id)
                end
                return score
            end
            
            def Alias.get_aliases(object_id)
                Alias.score_object(object_id)
                objs = @@objects.dup
                objs.delete(object_id)
                return objs
            end
            
            private
            
            def Alias.sum_objects(object_id)
                return 0 if @@objects.include?(object_id)
                @@objects << object_id
                object = Karma[object_id]
                score = object ? object.score : 0
                Alias.filter(:thing_id => object_id).each do |ali|
                    score += Alias.sum_objects(ali.aka.pk)
                end
                Alias.filter(:aka_id => object_id).each do |ali|
                    score += Alias.sum_objects(ali.thing.pk)
                end
                return score
            end
            
            def Alias.create_lock
                @@lock = Mutex.new
            end
            
        end
    end
end