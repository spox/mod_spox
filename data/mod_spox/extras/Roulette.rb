class Roulete < ModSpox::Plugin

    include RouletteDatatypes
    include Models
    include Messages::Outgoing
    
    def initialize(pipeline)
        super(pipeline)
        Signature.find_or_create(:signature => 'roulette', :plugin => name, :method => 'roulette')
        Signature.find_or_create(:signature => 'suicide', :plugin => name, :method => 'suicide')
        Signature.find_or_create(:signature => 'shoot (\S+)', :plugin => name, :method => 'shoot').params = [:nick]
        Signature.find_or_create(:signature => 'topten', :plugin => name, :method => 'topten')
        Signature.find_or_create(:signature => 'roulette stats (\S+)', :plugin => name, :method => 'stats').params = [:nick]
    end
    
    def roulette(message, params)
        return unless message.is_public?
        do_shot(message.source, message.target)
    end
    
    def suicide(message, params)
        return unless message.is_public?
        do_suicide(message.source, message.target)
    end
    
    def shoot(message, params)
        return unless message.is_public?
        cur_game = game(message.target)
        nick = Models::Nick.filter(:nick => params[:nick])
        if(game.shots == 1 && nick && Info.filter(:game_id => cur_game.pk, :nick_id => nick.pk))
            do_shot(nick, message.target)
        else
            do_suicide(message.source, message.target)
        end
    end
    
    def topten(message, params)
    end
    
    def stats(message, params)
    end
    
    private
    
    def do_shot(nick, channel)
        begin
            shot(nick, channel)
            @pipeline << Privmsg.new(channel, "#{nick.nick}: *click*")
        rescue Bullet => bang
            game_over(bang.game)
            #TODO: add banner here
            @pipeline << Privmsg.new(channel, "#{nick.nick}: *BANG*")
        end
    end
    
    def do_suicide(nick, channel)
        begin
            6.times do
                shot(nick, channel)
            end
        rescue Bullet => bang
            game_over(nick, bang.game)
            #TODO: add banner here
            @pipeline << Privmsg.new(channel, "#{nick.nick}: *BANG*")
        end
    end
    
    def game(channel)
        game = Game.filter(:shots > 0, :channel_id => channel.pk).first
        unless(game)
            chamber = rand(5) + 1
            game = Game.new(:chamber => chamber, :shots => chamber, :channel_id => channel.pk)
            game.save
        end
        return game
    end
    
    def shot(nick, channel)
        cur_game = game(channel)
        info = Info.find_or_create(:game_id => cur_game.pk, :nick_id => nick.pk)
        info.set(:shots => info.shots + 1)
        cur_game.set(:shots => cur_game.shots - 1)
        raise Bullet.new(cur_game) if cur_game.shots < 1
    end
    
    def game_over(nick, game)
        Info.filter(:game_id => game.pk).each do |info|
            info.set(:win => true) unless info.nick_id == nick.pk
        end
    end
end

module RouletteDatatypes
    class Game < Sequel::Model
        set_schema do
            primary_key :id
            timestamp :stamp, :null => false
            integer :shots, :null => false, :default => 6
            integer :chamber, :null => false, :default => 1
            foreign_key :channel_id, :null => false, :table => :channels
        end
        
        before_create do
            self.stamp = Time.now
        end
        
        def channel
            Models::Channel[channel_id]
        end
    end
    
    class Info < Sequel::Model
        set_schema do
            primary_key :id
            integer :shots, :null => false, :default => 0
            boolean :win, :null => false, :default => false
            foreign_key :nick_id, :null => false, :table => :nicks
            foreign_key :game_id, :null => false, :table => :games
        end
        
        def nick
            Models::Nick[nick_id]
        end
        
        def game
            Models::Game[game_id]
        end
    end
    
    class Bullet
        attr_reader :game
        def initialize(game)
            @game = game
        end
    end
end