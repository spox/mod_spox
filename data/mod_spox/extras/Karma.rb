class Karma < ModSpox::Plugin

    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        Datatype::Karma.create_table unless Datatype::Karma.table_exists?
        Datatype::Alias.create_table unless Datatype::Alias.table_exists?
        alias_group = Models::Group.find_or_create(:name => 'alias')
        add_sig(:sig => 'karma (?!(fight|alias|dealias|aliases|reset) (\S+|\(.+?\)) ?(\S+|\(.+?\))?$)(\S+|\(.+?\))', :method => :score, :desc => 'Returns karma for given thing', :params => [:crap, :crap2, :crap3, :thing])
        add_sig(:sig => 'karma reset (\S+|\(.+?\))', :method => :reset, :group => Models::Group.filter(:name => 'admin').first, :desc => 'Reset a karma score', :params => [:thing])
        add_sig(:sig => 'karma alias (\S+|\(.+?\)) (\S+|\(.+?\))', :method => :aka, :group => alias_group, :desc => 'Alias a karma object to another karma object', :params => [:thing, :thang])
        add_sig(:sig => 'karma dealias (\S+|\(.+?\)) (\S+|\(.+?\))', :method => :dealias, :group => alias_group, :desc => 'Remove a karma alias', :params => [:thing, :otherthing])
        add_sig(:sig => 'karma aliases (\S+|\(.+?\))', :method => :show_aliases, :desc => 'Show all aliases for given thing', :params => [:thing])
        add_sig(:sig => 'karma fight (\S+|\(.+?\)) (\S+|\(.+?\))', :method => :fight, :desc => 'Make two karma objects fight', :params => [:thing, :thang])
        add_sig(:sig => 'antikarma (\S+|\(.+?\))', :method => :antikarma, :desc => 'Show things antikarma', :params => [:thing])
        @pipeline.hook(self, :check, :Incoming_Privmsg)
        @thing_maxlen = 32
        @karma_regex = /(\(.{1,#@thing_maxlen}?\)|\S{1,#@thing_maxlen})([+-]{2})(?:\s|$)/
        @eggs = {}
        @eggs[:chameleon] = []
        @eggs[:chameleon] << 'Karma karma karma karma karma chameleon You come and go You come and go Loving would be easy if your colors were like my dream Red, gold and green Red, gold and green'
        @eggs[:chameleon] << 'Didn\'t hear your wicked words every day And you used to be so sweet I heard you say That my love was an addiction When we cling our love is strong When you go youre gone forever You string along You string along'
        @eggs[:chameleon] << 'Every day is like a survival You\'re my lover not my rival Every day is like a survival You\'re my lover not my rival'
        @eggs[:chameleon] << 'I\'m a man without conviction I\'m a man who doesnt know How to sell a contradication You come and go You come and go'
    end

    def check(message)
        if(message.is_public?)
            message.message.scan(@karma_regex) do |match|
                thing, adj = match
                thing.downcase!
                thing = thing[1..-2] if thing[0..0] == '(' && thing[-1..-1] == ')'
                adj = adj == '++' ? +1 : -1
                things = [thing]
                karma = Datatype::Karma.find_or_create(:thing => thing, :channel_id => message.target.pk)
                Datatype::Alias.get_aliases(karma.pk).each do |id|
                    things << Datatype::Karma[id].thing.downcase
                end
                if(things.include?(message.source.nick.downcase))
                    adj = -1
                end
                karma = Datatype::Karma.find_or_create(:thing => thing, :channel_id => message.target.pk)
                karma.score = karma.score + adj
                karma.save
            end
        end
    end

    def score(message, params)
        return unless message.is_public?
        thing = params[:thing]
        orig = thing[1..-2] if thing[0..0] == '(' && thing[-1..-1] == ')'
        orig = thing if orig.nil?
        thing = orig.downcase
        karma = Datatype::Karma.filter(:thing => thing, :channel_id => message.target.pk).first
        if(karma)
            @pipeline << Privmsg.new(message.replyto, "Karma for \2#{orig}\2 is #{Datatype::Alias.score_object(karma.pk)}")
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 #{orig} has no karma")
        end
        if(@eggs.has_key?(params[:thing].downcase.to_sym))
            @pipeline << Messages::Internal::TimerAdd.new(self, rand(5) + 1, nil, true){ egg(params[:thing].downcase, message) }
        end
    end

    def antikarma(message, params)
        return unless message.is_public?
        thing = params[:thing]
        orig = thing[1..-2] if thing[0..0] == '(' && thing[-1..-1] == ')'
        orig = thing if orig.nil?
        thing = orig.downcase
        karma = Datatype::Karma.filter(:thing => thing, :channel_id => message.target.pk).first
        if(karma)
            @pipeline << Privmsg.new(message.replyto, "Anti-Karma for \2#{orig}\2 is #{0 - Datatype::Alias.score_object(karma.pk).to_i}")
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 #{orig} has no anti-karma")
        end
    end

    def reset(message, params)
        sthing = params[:thing].downcase
        sthing = thing[1..-2] if thing[0..0] == '(' && thing[-1..-1] == ')'
        return unless message.is_public?
        karma = Datatype::Karma.filter(:thing => sthing, :channel_id => message.target.pk).first
        if(karma)
            karma.update(:score => 0)
            @pipeline << Privmsg.new(message.replyto, "Karma for \2#{karma.thing}\2 has been reset")
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 #{sthing} has no karma")
        end
    end

    def fight(message, params)
        thing = params[:thing]
        thang = params[:thang]
        thing = thing[1..-2] if thing[0..0] == '(' && thing[-1..-1] == ')'
        thang = thang[1..-2] if thang[0..0] == '(' && thang[-1..-1] == ')'
        rthing = Datatype::Karma.find_or_create(:thing => thing.downcase, :channel_id => message.target.pk)
        rthang = Datatype::Karma.find_or_create(:thing => thang.downcase, :channel_id => message.target.pk)
        thing_score = Datatype::Alias.score_object(rthing.pk)
        thang_score = Datatype::Alias.score_object(rthang.pk)
        winner = thing_score > thang_score ? thing : thang
        loser = thing_score > thang_score ? thang : thing
        distance = (thing_score - thang_score).abs
        output = "\2KARMA FIGHT RESULTS:\2 "
        if(distance > 0)
            reply message.replyto, "\2#{winner}\2 #{winner[-1] == 's' || winner[-1] == 115 ? 'have' : 'has'} beaten \2#{loser}\2 #{distance > 50 ? 'like a redheaded step child' : ''} (+#{distance} points)"
        else
            reply message.replyto, "\2#{winner}\2 #{winner[-1] == 's' || winner[-1] == 115 ? 'have' : 'has'} tied \2#{loser}\2"
        end
    end

    def aka(message, params)
        thing = params[:thing].downcase
        thang = params[:thang].downcase
        thing = thing[1..-2] if thing[0..0] == '(' && thing[-1..-1] == ')'
        thang = thang[1..-2] if thang[0..0] == '(' && thang[-1..-1] == ')'
        thing = Datatype::Karma.find_or_create(:thing => thing, :channel_id => message.target.pk)
        thang = Datatype::Karma.find_or_create(:thing => thang, :channel_id => message.target.pk)
        if(Datatype::Alias.filter('(thing_id = ? AND aka_id = ?) OR (thing_id = ? AND aka_id = ?)', thing.pk, thang.pk, thang.pk, thing.pk).first)
            reply message.replyto, "\2Error:\2 #{thing.thing} is already aliased to #{thang.thing}"
        else
            Datatype::Alias.find_or_create(:thing_id => thing.pk, :aka_id => thang.pk)
            reply message.replyto, "\2Karma Alias:\2 #{thing.thing} is now aliased to #{thang.thing}"
        end
    end

    def dealias(message, params)
        sthing = params[:thing].downcase
        sotherthing = params[:otherthing].downcase
        sthing = sthing[1..-2] if sthing[0..0] == '(' && sthing[-1..-1] == ')'
        sotherthing = sotherthing[1..-2] if sotherthing[0..0] == '(' && sotherthing[-1..-1] == ')'
        thing = Datatype::Karma.filter(:thing => sthing, :channel_id => message.target.pk).first
        otherthing = Datatype::Karma.filter(:thing => sotherthing, :channel_id => message.target.pk).first
        if(thing && otherthing)
            set = Datatype::Alias.filter('(thing_id = ? AND aka_id = ?) OR (thing_id = ? AND aka_id = ?)', thing.pk, otherthing.pk, otherthing.pk, thing.pk)
            if(set.count < 1)
                reply message.replyto, "\2Error:\2 No alias found between #{thing.thing} and #{otherthing.thing}"
            else
                set.destroy
                reply message.replyto, "#{thing.thing} has been successfully dealiased from #{otherthing.thing}"
            end
        else
            reply message.replyto, "\2Error:\2 No alias found between #{sthing} and #{sotherthing}"
        end
    end

    def show_aliases(message, params)
        thing = params[:thing].downcase
        thing = thing[1..-2] if thing[0..0] == '(' && thing[-1..-1] == ')'
        thing = Datatype::Karma.filter(:thing => thing, :channel_id => message.target.pk).first
        begin
            if(thing)
                things = []
                Datatype::Alias.get_aliases(thing.pk).each do |id|
                    things << Datatype::Karma[id].thing
                end
                if(things.empty?)
                    reply message.replyto, "#{thing.thing} is not currently aliased"
                else
                    reply message.replyto, "#{thing.thing} is currently aliased to: #{things.sort.join(', ')}"
                end
            else
                reply message.replyto, "\2Error:\2 #{params[:thing]} has never been used and has no aliases"
            end
        rescue Object
            error message.replyto, "No aliases found"
        end
    end
    
    def egg(karma, message)
        if(karma.downcase == 'chameleon')
            reply message.replyto, @eggs[:chameleon][rand(@eggs[:chameleon].size - 1)]
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