require 'mod_spox/messages/internal/PluginRequest'

class Roulette < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super(pipeline)
        add_sig(:sig => 'roulette', :method => :roulette, :req => 'public')
        add_sig(:sig => 'suicide', :method => :suicide, :req => 'public')
        add_sig(:sig => 'shoot (\S+)', :method => :shoot, :req => 'public', :params => [:nick])
        add_sig(:sig => 'roulette topten', :method => :topten, :req => 'public')
        add_sig(:sig => 'roulette stats ?(\S+)?', :method => :stats, :req => 'public', :params => [:nick])
        add_sig(:sig => 'roulette chambers', :method => :chambers, :req => 'public')
        Game.create_table unless Game.table_exists?
        Info.create_table unless Info.table_exists?
        @banner = nil
        @pipeline.hook(self, :get_banner, :Internal_PluginResponse)
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # Display chamber statistics
    def chambers(m, p)
        total = Game.all.size
        result = Game.group(:chamber).select(:chamber, 'COUNT(chamber) as total'.lit).reverse_order(:total)
        if(result)
            output = []
            result.each do |res|
                percent = sprintf('%.2d', ((res[:total].to_f / total.to_f) * 100.0))
                output << "chamber #{res.chamber}: #{percent}% (#{res[:total]})"
            end
            reply m.replyto, "\2Chamber stats:\2 #{output.join(', ')}"
        else
            reply m.replyto, "\2Error:\2 No games found"
        end
    end

    # message:: ModSpox::Messages::Internal::PluginResponse
    # Get the banner plugin
    def get_banner(message)
        @banner = message.plugin if message.found?
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: empty
    # Play roulette
    def roulette(message, params)
        return unless message.is_public?
        do_shot(message.source, message.target)
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: empty
    # Kill self
    def suicide(message, params)
        return unless message.is_public?
        do_suicide(message.source, message.target)
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: nick
    # Shoot other person playing current game
    def shoot(message, params)
        return unless message.is_public?
        cur_game = game(message.target)
        nick = Helpers.find_model(params[:nick], false)
        if(cur_game.shots == 1 && nick && Info.filter(:game_id => cur_game.pk, :nick_id => nick.pk))
            do_shot(nick, message.target)
        else
            do_suicide(message.source, message.target)
        end
    end

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: empty
    # List topten players
    def topten(message, params)
        return unless message.is_public?
        ds = Database.db[:infos].left_outer_join(:games, :id => :game_id)
        res = ds.select(:nick_id, 'COUNT(win) as wins'.lit).where(:channel_id => message.target.pk, :win => true).group(:nick_id).reverse_order(:wins).limit(10)
        ids = res.map(:nick_id)
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

    # message:: ModSpox::Messages::Incoming::Privmsg
    # params:: empty | nick
    # List statistics on self or given nick
    def stats(message, params)
        return unless message.is_public?
        if(params[:nick])
            nick =  Helpers.find_model(params[:nick], false)
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

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Report win/loss ratio for nick
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

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Return number of games nick has won
    def games_won(nick, channel)
        Info.left_outer_join(:games, :id => :game_id).filter('nick_id = ?', nick.pk).filter('channel_id = ?', channel.pk).filter('win = ?', true).count
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Return number of games nick has lost
    def games_lost(nick, channel)
        games_total(nick, channel) - games_won(nick, channel)
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Return number of games nick has played
    def games_total(nick, channel)
        Info.left_outer_join(:games, :id => :game_id).filter('nick_id = ?', nick.pk).filter('channel_id = ?', channel.pk).exclude(:game_id => game(channel).pk).count
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Return number of shots nick has taken
    def total_shots(nick, channel)
        v = Info.left_outer_join(:games, :id => :game_id).filter('nick_id = ?', nick.pk).filter('channel_id = ?', channel.pk).exclude(:game_id => game(channel).pk).sum(:infos__shots)
        v = 0 unless v
        return v
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Fire shot
    def do_shot(nick, channel)
        begin
            shot(nick, channel)
            reply(channel, "#{nick.nick}: *click*")
        rescue Bullet => bang
            game_over(nick, bang.game)
            kill_nick(nick, channel)
        end
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Commit suicide
    def do_suicide(nick, channel)
        begin
            6.times do
                shot(nick, channel)
            end
        rescue Bullet => bang
            game_over(nick, bang.game)
            kill_nick(nick, channel)
        end
    end

    def kill_nick(nick, channel)
        unless(@banner.nil?)
            begin
                @banner.plugin.ban(nick, channel, 30, '*BANG*', true, false)
            rescue Banner::NotOperator => boom
                reply(channel, "#{nick.nick}: *BANG*")
            rescue Object => boom
                reply(channel, "#{nick.nick}: *BANG*")
                Logger.warn("Error: Roulette ban generated an unexpected error: #{boom}")
            end
        else
            reply(channel, "#{nick.nick}: *BANG*")
        end
    end

    # channel:: ModSpox::Models::Channel
    # Return current game
    def game(channel)
        @pipeline << Messages::Internal::PluginRequest.new(self, 'Banner') if @banner.nil?
        game = Game.filter('shots > ?', 0).filter('channel_id = ?', channel.pk).first
        unless(game)
            chamber = rand(6) + 1
            game = Game.new(:chamber => chamber, :shots => chamber, :channel_id => channel.pk)
            game.save
        end
        return game
    end

    # nick:: ModSpox::Models::Nick
    # channel:: ModSpox::Models::Channel
    # Process shot
    def shot(nick, channel)
        cur_game = game(channel)
        info = Info.find_or_create(:game_id => cur_game.pk, :nick_id => nick.pk)
        info.update(:shots => info.shots + 1)
        cur_game.update(:shots => cur_game.shots - 1)
        raise Bullet.new(cur_game) if cur_game.shots < 1
    end

    # nick:: ModSpox::Models::Nick
    # game:: Game
    # Return number of games nick has won
    def game_over(nick, game)
        Info.filter(:game_id => game.pk).each do |info|
            info.update(:win => true) unless info.nick_id == nick.pk
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

        many_to_one :channel, :class => ModSpox::Models::Channel

        def before_create
            self.stamp = Time.now
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
        
        many_to_one :nick, :class => ModSpox::Models::Nick
        many_to_one :game, :class => Game
    end

    class Bullet < Exception
        attr_reader :game
        def initialize(game)
            @game = game
        end
    end
end