class Roulette < ModSpox::Plugin

    include Models
    
    def initialize(pipeline)
        super(pipeline)
        Signature.find_or_create(:signature => 'roulette', :plugin => name, :method => 'roulette')
        Signature.find_or_create(:signature => 'suicide', :plugin => name, :method => 'suicide')
        Signature.find_or_create(:signature => 'shoot (\S+)', :plugin => name, :method => 'shoot').params = [:nick]
        Signature.find_or_create(:signature => 'roulette topten', :plugin => name, :method => 'topten')
        Signature.find_or_create(:signature => 'roulette stats ?(\S+)?', :plugin => name, :method => 'stats').params = [:nick]
        Game.create_table unless Game.table_exists?
        Info.create_table unless Info.table_exists?
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
        nick = Nick.filter(:nick => params[:nick])
        if(cur_game.shots == 1 && nick && Info.filter(:game_id => cur_game.pk, :nick_id => nick.pk))
            do_shot(nick, message.target)
        else
            do_suicide(message.source, message.target)
        end
    end
    
    def topten(message, params)
        return unless message.is_public?
        ds = Database.db[:infos].left_outer_join(:games, :id => :game_id)
        ds.select!(:nick_id, :COUNT[:win] => :wins).where!(:channel_id => message.target.pk, :win => true).group!(:nick_id).order!(:wins.DESC).limit!(10)
        Logger.log(ds.sql)
        ids = ds.map(:nick_id)
        top = []
        ids.each do |id|
            nick = Nick[id]
            top << "#{nick.nick} (#{win_loss_ratio(nick, message.target)}% survival with #{games_won(nick, message.target)} wins)"
        end
        if(top.empty?)
            reply(message.replyto, "\2Error:\2 No one has survived")
        else
            reply(message.replyto, "Roulette topten: #{top.join(', ')}")
        end
    end
    
    def stats(message, params)
        return unless message.is_public?
        if(params[:nick])
            nick = Nick.filter(:nick => params[:nick]).first
            unless(nick)
                reply(message.replyto, "\2Error:\2 Failed to find record of #{params[:nick]}")
                return
            end
        else
            nick = message.source
        end
        reply(message.replyto, "\2Roulette stats #{nick.nick}:\2 #{win_loss_ratio(nick, message.target)}% survival rate. Has won #{games_won(nick, message.target)} games and lost #{games_lost(nick, message.target)} games, taking a total of #{total_shots(nick, message.target)} shots.")
    end
    
    private
    
    def win_loss_ratio(nick, channel)
        if(games_lost(nick, channel) > 0)
            val = (games_won(nick, channel).to_f / games_total(nick, channel).to_f) * 100
        elsif(games_lost(nick, channel) == 0 && games_won(nick, channel) == 0)
            val = 0
        else
            val = 100
        end
        return sprintf("%.2f", val)
    end
    
    def games_won(nick, channel)
        Info.left_outer_join(:games, :id => :game_id).filter{:nick_id == nick.pk && :channel_id == channel.pk && :win == true}.size
    end
    
    def games_lost(nick, channel)
        games_total(nick, channel) - games_won(nick, channel)
    end
    
    def games_total(nick, channel)
        Info.left_outer_join(:games, :id => :game_id).filter{:nick_id == nick.pk && :channel_id == channel.pk}.exclude(:game_id => game(channel).pk).size
    end
    
    def total_shots(nick, channel)
        v = Info.left_outer_join(:games, :id => :game_id).filter{:nick_id == nick.pk && :channel_id == channel.pk}.exclude(:game_id => game(channel).pk).sum(:infos__shots)
        v = 0 unless v
        return v
    end
    
    def do_shot(nick, channel)
        begin
            shot(nick, channel)
            reply(channel, "#{nick.nick}: *click*")
        rescue Bullet => bang
            game_over(nick, bang.game)
            #TODO: add banner here
            reply(channel, "#{nick.nick}: *BANG*")
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
            reply(channel, "#{nick.nick}: *BANG*")
        end
    end
    
    def game(channel)
        game = Game.filter{:shots > 0 && :channel_id == channel.pk}.first
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
    
    class Bullet < Exception
        attr_reader :game
        def initialize(game)
            @game = game
        end
    end
end